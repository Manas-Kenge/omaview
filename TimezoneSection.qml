import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "TimezonesModel.js" as Model

Item {
  id: root

  property var bar: null
  property var clockPanel: null
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string pluginPath: String(Qt.resolvedUrl("TimezoneSection.qml"))
    .replace(/^file:\/\//, "").replace(/\/TimezoneSection\.qml$/, "")
  readonly property var configuredTimezones: {
    var panelSettings = clockPanel ? clockPanel.settings : null
    if (panelSettings && panelSettings.timezones !== undefined)
      return panelSettings.timezones

    var host = clockPanel ? clockPanel.hostWidget : null
    var hostSettings = host ? host.settings : null
    return hostSettings && hostSettings.timezones !== undefined
      ? hostSettings.timezones : []
  }
  readonly property var timezones: Model.normalizeZones(configuredTimezones)
  property var zoneTimes: ({})
  property int epoch: Math.floor(clock.date.getTime() / 1000)

  width: parent ? parent.width : 0
  height: body.implicitHeight
  implicitHeight: height

  function refreshTimes() {
    var command = ["bash", root.pluginPath + "/get-times.sh", String(root.epoch)]
    for (var i = 0; i < root.timezones.length; i++) command.push(root.timezones[i])
    timesProcess.command = command
    timesProcess.running = false
    timesProcess.running = true
  }

  function entry(id) {
    return root.zoneTimes[id] || {}
  }

  function timeText(id) {
    var item = root.entry(id)
    return item.time24 || "--:--"
  }

  function detailText(id) {
    var item = root.entry(id)
    if (!item.abbr) return ""
    var badge = Model.dayBadge(item.date, root.entry("__local__").date)
    return item.abbr + (badge ? " · " + badge : "")
  }

  function saveTimezones(values) {
    if (!root.clockPanel || typeof root.clockPanel.persistSettings !== "function") return
    root.clockPanel.persistSettings({ timezones: Model.normalizeZones(values) })
  }

  onTimezonesChanged: {
    if (JSON.stringify(zonePicker.values) !== JSON.stringify(root.timezones))
      zonePicker.values = root.timezones.slice()
    if (timesProcess) root.refreshTimes()
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
    onDateChanged: {
      root.epoch = Math.floor(clock.date.getTime() / 1000)
      root.refreshTimes()
    }
  }

  Process {
    id: timesProcess
    stdout: StdioCollector {
      onStreamFinished: root.zoneTimes = Model.parseTimesOutput(text)
    }
  }

  Component.onCompleted: {
    root.refreshTimes()
  }

  Column {
    id: body
    width: parent.width
    spacing: Style.space(8)

    Item {
      width: parent.width
      height: Math.max(headerLabel.implicitHeight, clearButton.visible ? clearButton.implicitHeight : 0)

      PanelSectionHeader {
        id: headerLabel
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "TIME ZONES"
        foreground: root.foreground
        fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
      }

      Button {
        id: clearButton
        visible: root.timezones.length > 0
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: "Clear all"
        fontSize: Style.font.caption
        foreground: root.foreground
        accent: Color.accent
        fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        tooltipText: "Remove every tracked timezone"
        onClicked: root.saveTimezones([])
      }
    }

    MultiSelect {
      id: zonePicker
      width: parent.width
      values: root.timezones
      optionsCommand: ["bash", root.pluginPath + "/list-zones.sh"]
      placeholderText: "Search timezones…"
      emptyText: "No matches"
      noSelectionText: "None selected"
      foreground: root.foreground
      accent: Color.accent
      fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
      onChanged: function(values) { root.saveTimezones(values) }
    }

    Text {
      width: parent.width
      text: "Times update every minute · 󰑐 reloads the available zone list"
      color: Qt.darker(root.foreground, 1.7)
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    Column {
      width: parent.width
      spacing: Style.space(4)

      Flickable {
        id: timezoneScroll
        width: parent.width
        height: timezoneRow.implicitHeight
        contentWidth: timezoneRow.implicitWidth
        contentHeight: timezoneRow.implicitHeight
        clip: true
        interactive: contentWidth > width
        boundsBehavior: Flickable.StopAtBounds

        Row {
          id: timezoneRow
          spacing: Style.space(8)

          Repeater {
            model: root.timezones

            BorderSurface {
              required property string modelData
              width: Style.space(148)
              height: zoneContent.implicitHeight + Style.space(18)
              radius: Style.spacing.labelGap
              color: "transparent"
              borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)

              Column {
                id: zoneContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                spacing: Style.space(3)

                Text {
                  text: Model.friendlyName(modelData)
                  color: root.foreground
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                  width: parent.width
                }

                Text {
                  text: root.timeText(modelData)
                  color: root.foreground
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.subtitle
                  font.bold: true
                }

                Text {
                  visible: text !== ""
                  text: root.detailText(modelData)
                  color: Qt.darker(root.foreground, 1.5)
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.caption
                }
              }
            }
          }
        }
      }

      Text {
        visible: root.timezones.length === 0
        text: "No custom timezones selected"
        color: Qt.darker(root.foreground, 1.5)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.bodySmall
      }
    }

  }
}
