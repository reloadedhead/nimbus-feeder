import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "reloadedhead.nimbus"

  readonly property string binaryPath: Quickshell.env("HOME") + "/.local/bin/nimbus-feeder"
  property bool armed: false
  property bool bridged: false
  property string errorText: ""

  readonly property string statusText: {
    if (errorText !== "") return errorText
    if (!armed) return "Off"
    return bridged ? "Connected" : "Waiting for controller"
  }

  function toggleArmed() { armed = !armed }

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: proc
    running: root.armed
    command: [root.binaryPath]
    stdout: SplitParser {
      onRead: function(line) {
        if (line === "ACTIVE") { root.bridged = true; root.errorText = "" }
        else if (line === "WAITING") root.bridged = false
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.errorText = String(text || "").trim()
    }
    onExited: function(exitCode) {
      root.armed = false
      root.bridged = false
      if (exitCode !== 0 && root.errorText === "") root.errorText = "nimbus-feeder exited unexpectedly"
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uF11B"
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyWrap
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    Item {
      id: keyWrap
      anchors.fill: parent
      Keys.onEscapePressed: root.close()

      Column {
        id: column
        anchors.fill: parent
        spacing: Style.space(10)

        PanelHero {
          id: hero
          width: parent.width
          title: "Nimbus Gamepad Feeder"
          meta: root.statusText
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily

          iconComponent: Component {
            Text {
              textFormat: Text.PlainText
              text: "\uF11B"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.display
            }
          }

          trailingControl: Component {
            ToggleSwitch {
              checked: root.armed
              foreground: hero.foreground
              onToggled: root.toggleArmed()
            }
          }
        }

        PanelSeparator {
          visible: root.bridged
          foreground: root.bar.foreground
        }

        Text {
          textFormat: Text.PlainText
          visible: root.bridged
          width: parent.width
          text: "Your Nimbus controller will appear as an Xbox 360 Controller on apps like Steam or emulators."
          color: Qt.darker(root.bar.foreground, 1.5)
          wrapMode: Text.WordWrap
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Text {
          textFormat: Text.PlainText
          visible: root.errorText !== ""
          width: parent.width
          text: root.errorText
          color: Color.urgent
          wrapMode: Text.WordWrap
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
      }
    }
  }
}
