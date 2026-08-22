import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Item {
  id: root

  property var bar: null
  property var clockPanel: null
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string pluginPath: String(Qt.resolvedUrl("VitalsSection.qml"))
    .replace(/^file:\/\//, "").replace(/\/VitalsSection\.qml$/, "")

  property int cpuPercent: 0
  property int ramPercent: 0

  width: parent ? parent.width : 0
  height: body.implicitHeight
  implicitHeight: height

  function refresh() {
    vitalsProcess.command = ["bash", root.pluginPath + "/get-vitals.sh"]
    vitalsProcess.running = false
    vitalsProcess.running = true
  }

  function applyStats(text) {
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var parts = lines[i].trim().split("|")
      if (parts.length !== 2) continue
      var value = parseInt(parts[1], 10)
      if (!isFinite(value)) continue
      value = Math.max(0, Math.min(100, value))
      if (parts[0] === "cpu") root.cpuPercent = value
      else if (parts[0] === "ram") root.ramPercent = value
    }
  }

  Process {
    id: vitalsProcess
    stdout: StdioCollector { onStreamFinished: root.applyStats(text) }
  }

  Timer {
    id: pollTimer
    interval: 4000
    repeat: true
    running: root.clockPanel ? root.clockPanel.opened === true : false
    onTriggered: root.refresh()
  }

  Connections {
    target: root.clockPanel
    function onOpenedChanged() {
      if (root.clockPanel && root.clockPanel.opened === true) root.refresh()
    }
  }

  Component.onCompleted: root.refresh()

  component VitalRow: Item {
    id: vitalRow

    property string label
    property int percent: 0

    width: parent.width
    height: Style.space(16)

    Text {
      id: vitalLabel
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: vitalRow.label
      color: Qt.darker(root.foreground, 1.5)
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: true
      font.letterSpacing: 1
    }

    Rectangle {
      id: track
      anchors.left: vitalLabel.right
      anchors.right: percentLabel.left
      anchors.leftMargin: Style.space(12)
      anchors.rightMargin: Style.space(12)
      anchors.verticalCenter: parent.verticalCenter
      height: Style.space(6)
      radius: Style.cornerRadius > 0 ? height / 2 : 0
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)

      Rectangle {
        width: Math.round(parent.width * vitalRow.percent / 100)
        height: parent.height
        radius: parent.radius
        color: Style.selectedStateColor(root.foreground, Color.accent)

        Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
      }
    }

    Text {
      id: percentLabel
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: vitalRow.percent + "%"
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
  }

  Column {
    id: body
    width: parent.width
    spacing: Style.space(8)

    PanelSectionHeader {
      text: "SYSTEM"
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    VitalRow { label: "CPU"; percent: root.cpuPercent }
    VitalRow { label: "RAM"; percent: root.ramPercent }
  }
}
