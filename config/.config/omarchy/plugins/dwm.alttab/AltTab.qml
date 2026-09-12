import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Ui

Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false
  // Keeps the layer surface mapped while the out-animation plays.
  property bool closing: false
  // Picks the out-animation: commit zooms the selection, Esc just shrinks.
  property bool committed: false
  property bool sticky: false

  property var windows: []
  // One {x, y, w, h} per window, written by relayout() before windows changes
  // so delegates are born in their final place.
  property var rects: []
  property int layoutW: 0
  property int layoutH: 0
  property int selectedIndex: 0

  // Most-recently-used toplevels, newest first. Kept alive between opens by
  // keepLoaded, so opening the switcher never has to shell out to hyprctl.
  property var mru: []

  // Hover must not steal the preselection when the pointer already sits over
  // the grid, so it only arms once the pointer has really moved.
  property point mouseOrigin: Qt.point(-1, -1)
  property bool pointerArmed: false

  // ponytail: single calibration knob, multiplies every duration.
  readonly property real motion: 1.0

  readonly property var appLibrary: root.shell ? root.shell.appLibrary : null

  property int screenWidth: 1920
  property int screenHeight: 1080

  Component.onCompleted: seedMru()

  // Seed from Hyprland's focus history once at load; afterwards the
  // activeToplevel signal keeps the list ordered.
  function seedMru() {
    var list = []
    for (var i = 0; i < Hyprland.toplevels.values.length; i++) {
      var t = Hyprland.toplevels.values[i]
      if (t && t.wayland) list.push(t)
    }
    list.sort(function(a, b) {
      var ai = a.lastIpcObject ? a.lastIpcObject.focusHistoryID : 999
      var bi = b.lastIpcObject ? b.lastIpcObject.focusHistoryID : 999
      return ai - bi
    })
    var out = []
    for (var j = 0; j < list.length; j++) out.push(list[j].wayland)
    root.mru = out
  }

  function promote(tl) {
    if (!tl) return
    var out = [tl]
    for (var i = 0; i < root.mru.length; i++)
      if (root.mru[i] !== tl) out.push(root.mru[i])
    root.mru = out
  }

  Connections {
    target: ToplevelManager
    function onActiveToplevelChanged() { root.promote(ToplevelManager.activeToplevel) }
  }

  // A window closed while the overlay is up: drop it and reflow the survivors.
  Connections {
    target: ToplevelManager.toplevels
    function onObjectRemovedPost(object, index) { root.prune() }
  }

  function hyprFor(tl) {
    var list = Hyprland.toplevels.values
    for (var i = 0; i < list.length; i++)
      if (list[i].wayland === tl) return list[i]
    return null
  }

  function aspectOf(tl) {
    var h = root.hyprFor(tl)
    var s = h && h.lastIpcObject ? h.lastIpcObject.size : null
    var a = (s && s[0] > 0 && s[1] > 0) ? s[0] / s[1] : 16 / 9
    return Math.max(0.5, Math.min(2.6, a))
  }

  // Windows 11 gives every card its own window's aspect instead of a uniform
  // grid, so pack rows of equal height and shrink until they fit the screen.
  function relayout(list) {
    var n = list.length
    if (n === 0) { root.rects = []; root.layoutW = 0; root.layoutH = 0; return }

    var gap = Style.space(2)
    var W = Math.floor(root.screenWidth * 0.96)
    var H = Math.floor(root.screenHeight * 0.92)

    var aspects = []
    for (var i = 0; i < n; i++) aspects.push(root.aspectOf(list[i]))

    var rows = []
    var h = Math.floor(Math.min(H * 0.6, W / 2))
    for (var iter = 0; iter < 60; iter++) {
      rows = []
      var row = []
      var rw = 0
      for (var k = 0; k < n; k++) {
        var w = Math.min(W, Math.round(aspects[k] * h))
        if (row.length && rw + gap + w > W) {
          rows.push({ items: row, width: rw })
          row = []
          rw = 0
        }
        row.push({ i: k, w: w })
        rw += (row.length > 1 ? gap : 0) + w
      }
      if (row.length) rows.push({ items: row, width: rw })
      if (rows.length * (h + gap) - gap <= H) break
      h = Math.floor(h * 0.92)
      if (h < 80) break
    }

    var maxW = 0
    for (var r = 0; r < rows.length; r++) maxW = Math.max(maxW, rows[r].width)

    var out = new Array(n)
    var y = 0
    for (var r2 = 0; r2 < rows.length; r2++) {
      var x = Math.round((maxW - rows[r2].width) / 2)
      for (var c = 0; c < rows[r2].items.length; c++) {
        var it = rows[r2].items[c]
        out[it.i] = { x: x, y: y, w: it.w, h: h }
        x += it.w + gap
      }
      y += h + gap
    }

    root.layoutW = maxW
    root.layoutH = y - gap
    root.rects = out
  }

  // Rows are ragged, so Up/Down takes the nearest card by centre-x in the
  // adjacent row rather than a fixed column step.
  function vertical(dir) {
    var cur = root.rects[root.selectedIndex]
    if (!cur) return
    var cx = cur.x + cur.w / 2
    var best = -1
    var bestD = 1e12
    for (var i = 0; i < root.rects.length; i++) {
      var r = root.rects[i]
      if (!r) continue
      if (dir > 0 ? r.y <= cur.y : r.y >= cur.y) continue
      var d = Math.abs(r.y - cur.y) * 10000 + Math.abs(r.x + r.w / 2 - cx)
      if (d < bestD) { bestD = d; best = i }
    }
    if (best >= 0) root.selectedIndex = best
  }

  // Plugin lifecycle. The host calls open(payloadJson) on every
  // `omarchy-shell shell summon dwm.alttab ...`, and the global shortcuts call
  // it directly, so a repeat while the overlay is up means "advance the
  // selection", not "reopen".
  function open(payloadJson) {
    var payload = ({})
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) { payload = ({}) }
    var step = payload.dir === "prev" ? -1 : 1

    if (root.opened) { root.cycle(step); return }

    var live = ToplevelManager.toplevels.values
    var list = []
    for (var i = 0; i < root.mru.length; i++)
      if (live.indexOf(root.mru[i]) >= 0) list.push(root.mru[i])
    for (var j = 0; j < live.length; j++)
      if (list.indexOf(live[j]) < 0) list.push(live[j])

    if (payload.scope === "workspace") {
      var ws = Hyprland.focusedWorkspace
      list = list.filter(function(t) {
        var h = root.hyprFor(t)
        return h && h.workspace === ws
      })
    }

    if (list.length === 0) return

    closeTimer.stop()
    root.closing = false
    root.committed = false
    root.sticky = payload.sticky === true
    root.mouseOrigin = Qt.point(-1, -1)
    root.pointerArmed = false

    root.relayout(list)
    root.windows = list
    root.selectedIndex = list.length > 1 ? (step > 0 ? 1 : list.length - 1) : 0
    root.opened = true
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function cycle(step) {
    var n = root.windows.length
    if (n === 0) return
    root.selectedIndex = ((root.selectedIndex + step) % n + n) % n
  }

  function close() {
    if (!root.opened) return
    root.closing = true
    root.opened = false
    closeTimer.restart()
  }

  function commit() {
    if (!root.opened) return
    var tl = root.windows[root.selectedIndex]
    root.committed = true
    root.close()
    if (tl) tl.activate()
  }

  function closeWindow(i) {
    var tl = root.windows[i]
    if (tl) tl.close()
  }

  function prune() {
    if (root.windows.length === 0) return
    var live = ToplevelManager.toplevels.values
    var out = root.windows.filter(function(t) { return live.indexOf(t) >= 0 })
    if (out.length === root.windows.length) return
    if (out.length === 0) { root.close(); root.windows = []; return }
    root.relayout(out)
    root.windows = out
    root.selectedIndex = Math.min(root.selectedIndex, out.length - 1)
  }

  Timer {
    id: closeTimer
    interval: 280 * root.motion
    onTriggered: {
      root.closing = false
      root.committed = false
      // ponytail: dropping the delegates re-runs the cascade on the next open
      // and frees the capture buffers; keeping them warm would trade memory
      // for an instant re-open.
      root.windows = []
    }
  }

  // Driving the switcher from global shortcuts instead of `exec omarchy-shell`
  // means no process spawn per press, and the Alt release arrives even when
  // the tap is over before the layer surface takes keyboard focus.
  GlobalShortcut { appid: "dwm.alttab"; name: "next"; description: "Window switcher"; onPressed: root.open('{"dir":"next"}') }
  GlobalShortcut { appid: "dwm.alttab"; name: "prev"; description: "Window switcher (reverse)"; onPressed: root.open('{"dir":"prev"}') }
  GlobalShortcut { appid: "dwm.alttab"; name: "sticky"; description: "Window switcher (sticky)"; onPressed: root.open('{"sticky":true}') }
  GlobalShortcut { appid: "dwm.alttab"; name: "next-workspace"; description: "Window switcher (this workspace)"; onPressed: root.open('{"scope":"workspace"}') }
  GlobalShortcut {
    appid: "dwm.alttab"
    name: "alt"
    description: "Window switcher: commit on Alt release"
    onReleased: if (!root.sticky) root.commit()
  }

  function iconFor(appId) {
    if (!root.appLibrary) return ""
    var entry = DesktopEntries.heuristicLookup(appId || "")
    return root.appLibrary.iconSource(entry ? entry.icon : (appId || ""))
  }

  PanelWindow {
    id: panel
    visible: root.opened || root.closing
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "dwm-alttab"
    WlrLayershell.layer: WlrLayer.Overlay
    // Dropping the grab the moment the selection is committed lets the
    // activated window take the keyboard while the overlay fades out.
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    onWidthChanged: {
      root.screenWidth = width
      if (root.windows.length) root.relayout(root.windows)
    }
    onHeightChanged: {
      root.screenHeight = height
      if (root.windows.length) root.relayout(root.windows)
    }

    Rectangle {
      anchors.fill: parent
      color: Color.menu.scrim
      opacity: root.opened ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 180 * root.motion; easing.type: Easing.OutCubic } }

      HoverHandler {
        onPointChanged: {
          if (!root.opened || root.pointerArmed) return
          var p = point.position
          if (root.mouseOrigin.x < 0) { root.mouseOrigin = p; return }
          if (Math.hypot(p.x - root.mouseOrigin.x, p.y - root.mouseOrigin.y) > 6)
            root.pointerArmed = true
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.close()
      onWheel: function(wheel) { root.cycle(wheel.angleDelta.y < 0 ? 1 : -1) }
    }

    BorderSurface {
      id: sheet
      anchors.centerIn: parent
      width: root.layoutW + Style.space(2) * 2
      height: root.layoutH + Style.space(2) * 2
      radius: Style.cornerRadius
      color: Util.alpha(Color.menu.background, 0.92)
      padding: Style.space(2)
      transformOrigin: Item.Center
      opacity: 0
      scale: 0.92

      states: [
        State {
          name: "open"
          when: root.opened
          PropertyChanges { target: sheet; opacity: 1; scale: 1 }
        },
        State {
          name: "commit"
          when: root.closing && root.committed
          PropertyChanges { target: sheet; opacity: 0; scale: 1 }
        }
      ]

      transitions: [
        Transition {
          to: "open"
          NumberAnimation { properties: "opacity,scale"; duration: 260 * root.motion; easing.type: Easing.OutBack }
        },
        Transition {
          to: "commit"
          NumberAnimation { properties: "opacity"; duration: 160 * root.motion; easing.type: Easing.OutCubic }
        },
        // ponytail: Esc lands back on the base scale 0.92 rather than a
        // dedicated 0.95; the difference is not visible at 140ms.
        Transition {
          to: ""
          NumberAnimation { properties: "opacity,scale"; duration: 140 * root.motion; easing.type: Easing.OutCubic }
        }
      ]

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
          switch (event.key) {
          case Qt.Key_Escape:
            root.close(); break
          case Qt.Key_Tab:
          case Qt.Key_Right:
            root.cycle(1); break
          case Qt.Key_Backtab:
          case Qt.Key_Left:
            root.cycle(-1); break
          case Qt.Key_Down:
            root.vertical(1); break
          case Qt.Key_Up:
            root.vertical(-1); break
          case Qt.Key_Return:
          case Qt.Key_Enter:
          case Qt.Key_Space:
            root.commit(); break
          case Qt.Key_Delete:
            root.closeWindow(root.selectedIndex); break
          default:
            if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9
                && event.key - Qt.Key_1 < root.windows.length) {
              root.selectedIndex = event.key - Qt.Key_1
              root.commit()
              break
            }
            return
          }
          event.accepted = true
        }

        // The Windows behaviour: releasing Alt commits the selection. The
        // global shortcut handles this for real taps; this is the fallback
        // once the surface already owns the keyboard.
        Keys.onReleased: function(event) {
          if ((event.key === Qt.Key_Alt || event.key === Qt.Key_Meta) && !root.sticky) {
            root.commit()
            event.accepted = true
          }
        }

        Item {
          id: content
          anchors.centerIn: parent
          width: root.layoutW
          height: root.layoutH

          Repeater {
            model: ScriptModel { values: root.windows }

            Item {
              id: cardRoot

              required property int index
              required property var modelData

              readonly property var r: root.rects[index]
              readonly property bool selected: index === root.selectedIndex
              readonly property var hypr: root.hyprFor(modelData)
              property bool hovered: false

              x: r ? r.x : 0
              y: r ? r.y : 0
              width: r ? r.w : 0
              height: r ? r.h : 0
              z: selected ? 2 : hovered ? 1 : 0
              transformOrigin: Item.Center
              scale: root.committed ? (selected ? 1.1 : 0.96)
                                    : selected ? 1.04 : hovered ? 1.02 : 1
              opacity: root.committed ? 0 : selected ? 1 : 0.82

              Behavior on x { enabled: !cascade.running; NumberAnimation { duration: 220 * root.motion; easing.type: Easing.OutCubic } }
              Behavior on y { enabled: !cascade.running; NumberAnimation { duration: 220 * root.motion; easing.type: Easing.OutCubic } }
              Behavior on width { enabled: !cascade.running; NumberAnimation { duration: 220 * root.motion; easing.type: Easing.OutCubic } }
              Behavior on height { enabled: !cascade.running; NumberAnimation { duration: 220 * root.motion; easing.type: Easing.OutCubic } }
              Behavior on scale { SpringAnimation { spring: 3; damping: 0.3; epsilon: 0.003 } }
              Behavior on opacity { NumberAnimation { duration: 160 * root.motion; easing.type: Easing.OutCubic } }

              // The cascade drives an inner item so it never fights the
              // selection/commit behaviours on the delegate itself.
              Item {
                id: card
                anchors.fill: parent
                opacity: 0
                scale: 0.85
                transformOrigin: Item.Center

                SequentialAnimation {
                  id: cascade
                  running: true
                  PauseAnimation { duration: Math.min(cardRoot.index, 12) * 30 * root.motion }
                  ParallelAnimation {
                    NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 200 * root.motion; easing.type: Easing.OutCubic }
                    NumberAnimation { target: card; property: "scale"; from: 0.85; to: 1; duration: 260 * root.motion; easing.type: Easing.OutBack }
                  }
                }

                Rectangle {
                  id: plate
                  anchors.fill: parent
                  radius: Style.cornerRadius
                  color: Color.menu.selectedBackground
                  clip: true

                  // Shown until the first captured frame lands, so a card is
                  // never blank while the overlay is animating in.
                  IconImage {
                    anchors.centerIn: parent
                    width: 96
                    height: 96
                    source: root.iconFor(cardRoot.modelData ? cardRoot.modelData.appId : "")
                    opacity: preview.hasContent ? 0 : 0.9
                    Behavior on opacity { NumberAnimation { duration: 180 * root.motion; easing.type: Easing.OutCubic } }
                  }

                  // ScreencopyView reports the toplevel's own size, so scale it
                  // down into the card by hand instead of letting it paint at
                  // full window resolution.
                  ScreencopyView {
                    id: preview
                    anchors.centerIn: parent
                    captureSource: cardRoot.modelData
                    live: root.opened
                    constraintSize: Qt.size(plate.width, plate.height)
                    readonly property real fit: (sourceSize.width > 0 && sourceSize.height > 0)
                      ? Math.min(plate.width / sourceSize.width, plate.height / sourceSize.height)
                      : 0
                    width: fit > 0 ? sourceSize.width * fit : plate.width
                    height: fit > 0 ? sourceSize.height * fit : plate.height
                    opacity: hasContent ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180 * root.motion; easing.type: Easing.OutCubic } }
                  }

                  // Windows 11 puts the icon and title in a strip over the top of
                  // the thumbnail rather than below it, so the preview gets the
                  // whole card.
                  Rectangle {
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: 48
                    gradient: Gradient {
                      GradientStop { position: 0; color: Util.alpha(Color.menu.background, 0.85) }
                      GradientStop { position: 1; color: Util.alpha(Color.menu.background, 0) }
                    }

                    Row {
                      anchors.fill: parent
                      anchors.margins: Style.space(1)
                      spacing: Style.space(1)

                      IconImage {
                        width: 28; height: 28
                        anchors.verticalCenter: parent.verticalCenter
                        source: root.iconFor(cardRoot.modelData ? cardRoot.modelData.appId : "")
                      }

                      Text {
                        width: parent.width - 28 * 2 - Style.space(1) * 2
                        anchors.verticalCenter: parent.verticalCenter
                        text: cardRoot.modelData ? cardRoot.modelData.title : ""
                        elide: Text.ElideRight
                        color: cardRoot.selected ? Color.menu.selectedText : Color.menu.text
                        font.family: Style.font.menuFamily
                        font.pixelSize: Style.font.subtitle
                      }
                    }
                  }

                  Rectangle {
                    anchors { right: parent.right; bottom: parent.bottom; margins: Style.space(1) }
                    width: badge.implicitWidth + Style.space(2)
                    height: badge.implicitHeight + Style.space(1)
                    radius: Style.cornerRadius
                    color: Util.alpha(Color.menu.background, 0.85)
                    visible: badge.text !== ""

                    Text {
                      id: badge
                      anchors.centerIn: parent
                      readonly property var ws: cardRoot.hypr ? cardRoot.hypr.workspace : null
                      readonly property var mon: cardRoot.hypr ? cardRoot.hypr.monitor : null
                      text: (ws ? ws.name : "")
                            + (mon && mon !== Hyprland.focusedMonitor ? "  " + mon.name : "")
                      color: Color.menu.text
                      font.family: Style.font.menuFamily
                      font.pixelSize: Style.font.caption
                    }
                  }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onPositionChanged: {
                  if (!root.pointerArmed) return
                  cardRoot.hovered = true
                  root.selectedIndex = cardRoot.index
                }
                onExited: cardRoot.hovered = false
                onClicked: function(mouse) {
                  if (mouse.button === Qt.MiddleButton) {
                    root.closeWindow(cardRoot.index)
                  } else {
                    root.selectedIndex = cardRoot.index
                    root.commit()
                  }
                }
              }

              // Declared after the card's MouseArea so it wins the click, and
              // left non-hovering so the card underneath keeps its hover state.
              MouseArea {
                anchors { top: parent.top; right: parent.right }
                width: 28 + Style.space(2)
                height: 48
                visible: cardRoot.hovered
                onClicked: root.closeWindow(cardRoot.index)

                Text {
                  anchors.centerIn: parent
                  text: "✕"
                  color: Color.menu.text
                  font.family: Style.font.menuFamily
                  font.pixelSize: Style.font.body
                }
              }
            }
          }

          // One ring glides between cards instead of each card drawing its own
          // border, which is what gives the selection its motion.
          Rectangle {
            id: ring
            readonly property var r: root.rects[root.selectedIndex]
            readonly property int pad: 6

            x: r ? r.x - pad : 0
            y: r ? r.y - pad : 0
            width: r ? r.w + pad * 2 : 0
            height: r ? r.h + pad * 2 : 0
            radius: Style.cornerRadius + pad
            color: "transparent"
            border.width: 2
            border.color: Color.accent
            visible: r !== undefined
            z: 10

            Behavior on x { enabled: root.opened; SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.25 } }
            Behavior on y { enabled: root.opened; SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.25 } }
            Behavior on width { enabled: root.opened; SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.25 } }
            Behavior on height { enabled: root.opened; SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.25 } }

            layer.enabled: true
            layer.effect: MultiEffect {
              shadowEnabled: true
              shadowColor: Color.accent
              shadowBlur: 1.0
              shadowScale: 1.02
              shadowOpacity: 0.35

              SequentialAnimation on shadowOpacity {
                running: root.opened
                loops: Animation.Infinite
                NumberAnimation { to: 0.7; duration: 1400 * root.motion; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.35; duration: 1400 * root.motion; easing.type: Easing.InOutSine }
              }
            }
          }
        }
      }
    }
  }
}
