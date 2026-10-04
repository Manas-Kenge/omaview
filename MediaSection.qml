import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Commons
import qs.Ui

Item {
  id: root

  property var bar: null
  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var sourcePlayers: {
    var sources = []
    for (var i = 0; i < players.length; i++) {
      var player = players[i]
      if (player && (player.trackTitle || player.trackArtist)) sources.push(player)
    }
    sources.sort(function(a, b) {
      if (!!a.isPlaying !== !!b.isPlaying) return a.isPlaying ? -1 : 1
      return root.playerLabel(a).localeCompare(root.playerLabel(b))
    })
    return sources
  }
  readonly property color foreground: bar ? bar.foreground : Color.foreground

  visible: sourcePlayers.length > 0
  width: parent ? parent.width : 0
  height: visible ? body.implicitHeight : 0
  implicitHeight: height

  function playerLabel(player) {
    if (!player) return ""
    var value = player.identity || player.desktopEntry || player.dbusName || "Media"
    return String(value).replace(/^org\.mpris\.MediaPlayer2\./, "")
  }

  function togglePlaying(player) {
    if (!player) return
    if (player.isPlaying && player.canPause) player.pause()
    else if (!player.isPlaying && player.canPlay) player.play()
    else if (player.canTogglePlaying) player.togglePlaying()
  }

  Column {
    id: body
    width: parent.width
    spacing: Style.space(8)

    PanelSectionHeader {
      text: "MEDIA"
      foreground: root.foreground
    }

    Repeater {
      model: root.sourcePlayers

      BorderSurface {
        required property var modelData
        required property int index
        width: body.width
        height: card.implicitHeight + Style.space(22)
        radius: Style.spacing.labelGap
        color: "transparent"
        borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)

        Column {
          id: card
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.leftMargin: Style.space(12)
          anchors.rightMargin: Style.space(12)
          anchors.topMargin: Style.space(11)
          spacing: Style.space(9)

          Row {
            width: parent.width
            spacing: Style.space(8)

            BorderSurface {
              width: Style.space(72)
              height: Style.space(72)
              radius: Style.spacing.labelGap
              color: Style.normalFillFor(root.foreground, Color.accent)
              borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)

              Image {
                anchors.fill: parent
                anchors.margins: Style.space(2)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                source: modelData && modelData.trackArtUrl ? modelData.trackArtUrl : ""
                visible: source !== ""
              }

              Text {
                anchors.centerIn: parent
                visible: !modelData || !modelData.trackArtUrl
                text: "󰝚"
                color: root.foreground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.displayLarge
              }
            }

            Column {
              width: parent.width - Style.space(82)
              spacing: Style.space(2)
              anchors.verticalCenter: parent.verticalCenter

              Text {
                text: modelData && modelData.trackTitle ? modelData.trackTitle : "Nothing playing"
                color: root.foreground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.body
                font.bold: modelData && modelData.isPlaying
                elide: Text.ElideRight
                width: parent.width
              }

              Text {
                text: modelData && modelData.trackArtist
                  ? modelData.trackArtist : root.playerLabel(modelData)
                color: Qt.darker(root.foreground, 1.35)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
                width: parent.width
              }

              Text {
                visible: !!(modelData && modelData.trackAlbum)
                text: modelData && modelData.trackAlbum ? modelData.trackAlbum : ""
                color: Qt.darker(root.foreground, 1.5)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
                width: parent.width
              }

              Text {
                text: root.playerLabel(modelData)
                color: Qt.darker(root.foreground, 1.6)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
                width: parent.width
              }
            }
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(8)

            Button {
              iconText: "󰒮"
              foreground: root.foreground
              horizontalPadding: Style.spacing.controlPaddingX
              verticalPadding: Style.spacing.controlPaddingY
              enabled: modelData && modelData.canGoPrevious
              opacity: enabled ? 1.0 : 0.4
              onClicked: if (modelData && modelData.canGoPrevious) modelData.previous()
            }

            Button {
              iconText: modelData && modelData.isPlaying ? "󰏤" : "󰐊"
              foreground: root.foreground
              horizontalPadding: Style.spacing.panelGap
              verticalPadding: Style.spacing.controlPaddingY
              iconSize: Style.font.iconLarge
              enabled: modelData && (modelData.canTogglePlaying
                || modelData.canPlay || modelData.canPause)
              opacity: enabled ? 1.0 : 0.4
              onClicked: root.togglePlaying(modelData)
            }

            Button {
              iconText: "󰒭"
              foreground: root.foreground
              horizontalPadding: Style.spacing.controlPaddingX
              verticalPadding: Style.spacing.controlPaddingY
              enabled: modelData && modelData.canGoNext
              opacity: enabled ? 1.0 : 0.4
              onClicked: if (modelData && modelData.canGoNext) modelData.next()
            }
          }
        }
      }
    }
  }

}
