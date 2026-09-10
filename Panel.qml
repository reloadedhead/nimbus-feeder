import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "reloadedhead.nimbus"

  readonly property string binaryPath: Quickshell.env("HOME") + "/.local/bin/nimbus-feeder"
  readonly property string pluginRoot: Quickshell.env("HOME") + "/.config/omarchy/plugins/reloadedhead.nimbus"
  readonly property string setupScript: pluginRoot + "/bin/nimbus-setup-udev"
  readonly property string udevRulePath: pluginRoot + "/udev/99-nimbus.rules"

  property bool armed: false
  property bool bridged: false
  property string errorText: ""
  property bool fixApplied: false

  readonly property bool permissionError: errorText.indexOf("Permission denied") !== -1

  readonly property string statusText: {
    if (fixApplied) return "Reboot pending"
    if (permissionError) return "Missing permissions"
    if (errorText !== "") return "Error"
    if (!armed) return "Off"
    return bridged ? "Connected" : "Waiting for controller"
  }

  function toggleArmed() { armed = !armed }

  function fixPermissions() {
    if (fixProcess.running) return
    fixApplied = false
    fixProcess.running = true
  }

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: proc
    running: root.armed
    command: [root.binaryPath]
    stdout: SplitParser {
      onRead: function(line) {
        if (line === "ACTIVE") { root.bridged = true; root.errorText = ""; root.fixApplied = false }
        else if (line === "WAITING") { root.bridged = false; root.fixApplied = false }
        else if (line.indexOf("ERROR: ") === 0) root.errorText = line.slice(7)
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var t = String(text || "").trim()
        if (t !== "") root.errorText = t
      }
    }
    onExited: function(exitCode) {
      root.armed = false
      root.bridged = false
      if (exitCode !== 0 && root.errorText === "") root.errorText = "nimbus-feeder exited unexpectedly"
    }
  }

  Process {
    id: fixProcess
    running: false
    property string _stderr: ""
    command: ["pkexec", root.setupScript, root.udevRulePath, Quickshell.env("USER") || Quickshell.env("LOGNAME")]
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: fixProcess._stderr = String(text || "").trim()
    }
    onExited: function(exitCode) {
      if (exitCode === 0) {
        root.fixApplied = true
        root.errorText = ""
      } else {
        root.errorText = fixProcess._stderr || "Fix permissions failed"
      }
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
              interactive: !root.permissionError
              opacity: root.permissionError ? 0.5 : 1.0
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
          visible: root.errorText !== "" && !root.permissionError
          width: parent.width
          text: root.errorText
          color: Color.urgent
          wrapMode: Text.WordWrap
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Column {
          visible: root.permissionError
          width: parent.width
          spacing: Style.space(8)

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: "Nimbus needs one-time permission setup to read the controller without root."
            color: Color.urgent
            wrapMode: Text.WordWrap
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Button {
            text: fixProcess.running ? "Requesting permission…" : "Fix permissions"
            enabled: !fixProcess.running
            bordered: true
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            onClicked: root.fixPermissions()
          }
        }

        Text {
          textFormat: Text.PlainText
          visible: root.fixApplied
          width: parent.width
          text: "Permissions fixed. Reboot for it to take effect, then arm again."
          color: Qt.darker(root.bar.foreground, 1.5)
          wrapMode: Text.WordWrap
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
      }
    }
  }
}
