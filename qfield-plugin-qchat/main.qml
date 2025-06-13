import QtQuick
import QtQuick.Controls
import QtWebSockets
import QtCore

import org.qfield
import org.qgis
import Theme

import "qrc:/qml" as QFieldItems

Item {
  id: plugin

  property var mainWindow: iface.mainWindow()
  property var mapCanvas: iface.mapCanvas()

  Settings {
    id: qchatSettings
    property string lastUrl: 'gischat.geotribu.net'//wss://gischat.geotribu.net/room/QGIS/ws'
    property string lastRoom: 'QGIS'
    property string lastUserName: 'Geotribu'
  }

  Component.onCompleted: {
    userNameInput.text = qchatSettings.lastUserName
    serverUrlField.text = qchatSettings.lastUrl
    serverRoomField.text = qchatSettings.lastRoom

    iface.addItemToPluginsToolbar(pluginButton)
  }

  Dialog {
    id: connectionDialog
    title: qsTr("Connection - QChat")
    focus: true
    font: Theme.defaultFont
    parent: mainWindow.contentItem

    x: (mainWindow.width - width) / 2
    y: (mainWindow.height - height - 80) / 2

    Column {
      width: childrenRect.width
      height: childrenRect.height
      spacing: 10

      TextMetrics {
        id: labelMetrics
        font: connectionLabel.font
        text: connectionLabel.text
      }

      Label {
        id: connectionLabel
        width: mainWindow.width - 60 < labelMetrics.width ? mainWindow.width - 60 : labelMetrics.width
        text: qsTr("Pick a server, a room, and enter your user identifier below.")
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor
      }

      ComboBox {
        id: serverUrlComboBox
        width: connectionLabel.width
        font: Theme.defaultFont
        editable: true
        enabled: ws.status == WebSocket.Closed
        model: {
          let servers = ['gischat.geotribu.net', 'gischat.geotribu.fr']
          if (qchatSettings.lastUrl != "" && servers.indexOf(qchatSettings.lastUrl) < 0) {
            servers.push(qchatSettings.lastUrl)
          }
          return servers
        }

        contentItem: TextField {
          id: serverUrlField
        
          inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase
          enabled: ws.status == WebSocket.Closed
          font: Theme.defaultFont
          text: parent.displayText
          placeholderText: qsTr("Server")

          onTextChanged: {
            getRoomsTimer.restart();
          }
        }

        background: Rectangle {
          color: "transparent"
        }

        Component.onCompleted: {
          currentIndex = find(qchatSettings.lastUrl);
          getRoomsTimer.restart();
        }

        onModelChanged: {
          currentIndex = find(qchatSettings.lastUrl);
        }

        onDisplayTextChanged: {
          serverUrlField.text = displayText;
        }
      }

      ComboBox {
        id: serverRoomComboBox
        width: connectionLabel.width
        font: Theme.defaultFont
        editable: true
        enabled: ws.status == WebSocket.Closed
        model: []

        contentItem: TextField {
          id: serverRoomField
        
          inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase
          enabled: ws.status == WebSocket.Closed
          font: Theme.defaultFont
          text: parent.displayText
          placeholderText: qsTr("Room")
        }

        background: Rectangle {
          color: "transparent"
        }

        Component.onCompleted: {
          currentIndex = find(qchatSettings.lastRoom);
        }

        onModelChanged: {
          currentIndex = find(qchatSettings.lastRoom);
        }

        onDisplayTextChanged: {
          serverRoomField.text = displayText;
        }
      }
      
      TextField {
        id: userNameInput
        width: connectionLabel.width
        font: Theme.defaultFont
        enabled: ws.status == WebSocket.Closed
        placeholderText: "User name"
      }
    }

    standardButtons: Dialog.Ok | Dialog.Close

    onAccepted: {
      ws.active = false
      ws.url = "wss://"+serverUrlField.text.trim()+"/room/"+serverRoomField.text.trim()+"/ws"
      ws.active = true

      qchatSettings.lastUserName = userNameInput.text.trim()
      qchatSettings.lastRoom = serverRoomField.text.trim()
      qchatSettings.lastUrl = serverUrlField.text.trim()
    }

    Component.onCompleted: {
      standardButton(Dialog.Ok).text = "Connect"
    }

    Timer {
      id: getRoomsTimer
      interval: 500
      repeat: false
      running: false

      onTriggered: {
        connectionDialog.getRooms();
      }
    }

    function getRooms() {
      const url = "https://"+serverUrlField.text.trim()+"/rooms";
      let request = new XMLHttpRequest();

      request.onreadystatechange = function() {
        if (request.readyState === XMLHttpRequest.DONE) {
          let responseArray = JSON.parse(request.response)
          console.log(responseArray);
          console.log(request.response);
          serverRoomComboBox.model = responseArray;
        }
      }

      request.open("GET", url);
      request.send();
    }
  }

  Dialog {
    id: detailsDialog
    title: qsTr("QChat")
    focus: true
    font: Theme.defaultFont
    parent: mainWindow.contentItem

    x: (mainWindow.width - width) / 2
    y: (mainWindow.height - height - 80) / 2

    onAboutToShow: {
      //swipe.currentIndex = 0;
    }

    SwipeView {
      id: swipe
      width: mainWindow.width - 60 < labelMetrics.width ? mainWindow.width - 60 : labelMetrics.width
      clip: true
      interactive: false

      Column {
        id: detailsContent
        width: mainWindow.width - 60 < labelMetrics.width ? mainWindow.width - 60 : labelMetrics.width
        spacing: 10

        ScrollView {
          id: historyView
          leftPadding: 0
          rightPadding: 0
          topPadding: 0
          bottomPadding: 0
          ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
          ScrollBar.vertical: QfScrollBar {
          }
          width: parent.width
          height: Math.min(historyContainer.height, mainWindow.height - 200)
          contentWidth: parent.width
          contentHeight: historyContainer.height
          clip: true

          Column {
            id: historyContainer
            width: parent.width
            height: childrenRect.height
            spacing: 10

            Repeater {
              id: historyRepeater
              model: ListModel {
                id: historyModel
              }

              onCountChanged: {
                historyView.ScrollBar.vertical.position = historyView.contentHeight
              }

              width: parent.width

              Column {
                width: parent.width
                spacing: 2

                Label {
                  width: parent.width
                  font: Theme.tipFont
                  color: Theme.secondaryTextColor
                  wrapMode: Text.WordWrap
                  text: {
                    switch (historyType) {
                    case plugin.qchat_message_type_text:
                      return "<i>" + qsTr("%1 said").arg(historyData.author) + "</i>";
                    case plugin.qchat_message_type_image:
                      return "<i>" + qsTr("%1 sent an image").arg(historyData.author) + "</i>";
                    case plugin.qchat_message_type_bbox:
                      return "<i>" + qsTr("%1 sent an extent").arg(historyData.author) + "</i>";
                    }
                    return "";
                  }
                }

                Label {
                  visible: historyType == plugin.qchat_message_type_text
                  width: parent.width
                  font: Theme.defaultFont
                  color: Theme.mainTextColor
                  wrapMode: Text.WordWrap
                  text: historyData.text || ""
                }

                Image {
                  visible: historyType == plugin.qchat_message_type_image
                  height: historyType == plugin.qchat_message_type_image ? 100 : 0;
                  source: historyType == plugin.qchat_message_type_image ? "data:image/png;base64," + historyData.image_data : "";
                  fillMode: Image.PreserveAspectFit;

                  onStatusChanged: {
                    if (source !== "" && status == Image.Ready) {
                      historyView.ScrollBar.vertical.position = historyView.contentHeight
                    }
                  }

                  MouseArea {
                    anchors.fill: parent

                    onClicked: {
                      zoomedImage.source = parent.source;
                      swipe.currentIndex = 1;
                    }
                  }
                }

                QfButton {
                  visible: historyType == plugin.qchat_message_type_bbox
                  width: parent.width
                  borderColor: Theme.mainTextColor
                  color: Theme.mainTextColor
                  bgcolor: "transparent"
                  text: qsTr("Zoom to extent")

                  onClicked: {
                    const wkt = "MULTIPOINT((" + historyData.xmin + " " + historyData.ymin + "),(" + historyData.xmax + " " + historyData.ymax + "))";
                    const geom = GeometryUtils.createGeometryFromWkt(wkt);
                    const bbox = GeometryUtils.boundingBox(geom);
                    const bboxCrs = CoordinateReferenceSystemUtils.fromDescription(historyData.crs_authid);
                    mapCanvas.mapSettings.extent = GeometryUtils.reprojectRectangle(bbox, bboxCrs, mapCanvas.mapSettings.destinationCrs);
                  }
                }
              }
            }
          }
        }

        Row {
          width: parent.width
          spacing: 10

          TextField {
            id: messageInput
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 116
            font: Theme.defaultFont
            placeholderText: "Message content"
          }

          QfToolButton {
            round: true
            iconSource: "resources/img/send.svg"
            iconColor: Theme.mainTextColor
            bgcolor: "transparent"

            onClicked: {
              if (messageInput.text !== "") {
                const event = JSON.stringify({"type": plugin.qchat_message_type_text, "author": qchatSettings.lastUserName, "avatar": "", "text": messageInput.text})
                ws.sendTextMessage(event);
                messageInput.text = "";
              }
            }
          }

          QfToolButton {
            round: true
            iconSource: Theme.getThemeVectorIcon("ic_map_white_24dp")
            iconColor: Theme.mainTextColor
            bgcolor: "transparent"

            onClicked: {
              mapCanvas.grabToImage(function(result) {
                grabImage.source = result.url
              });
            }
          }
        }
      }

      Column {
        width: mainWindow.width - 60 < labelMetrics.width ? mainWindow.width - 60 : labelMetrics.width

        Image {
          id: zoomedImage
          width: parent.width
          height: detailsContent.childrenRect.height
          fillMode: Image.PreserveAspectFit;
          source: ""

          MouseArea {
            anchors.fill: parent
            onClicked: {
              swipe.currentIndex = 0;
              zoomedImage.source = "";
            }
          }
        }
      }
    }

    standardButtons: Dialog.Ok | Dialog.Close

    onAccepted: {
      const event = JSON.stringify({"type": plugin.qchat_message_type_exiter, "exiter": qchatSettings.lastUserName})
      ws.sendTextMessage(event);
      ws.active = false
      historyModel.clear()
    }

    Component.onCompleted: {
      standardButton(Dialog.Ok).text = "Disconnect"
    }
  }

  readonly property string qchat_message_type_bbox: "bbox"
  readonly property string qchat_message_type_crs: "crs"
  readonly property string qchat_message_type_exiter: "exiter"
  readonly property string qchat_message_type_geojson: "geojson"
  readonly property string qchat_message_type_image: "image"
  readonly property string qchat_message_type_like: "like"
  readonly property string qchat_message_type_nb_users: "nb_users"
  readonly property string qchat_message_type_newcomer: "newcomer"
  readonly property string qchat_message_type_text: "text"
  readonly property string qchat_message_type_uncompliant: "uncompliant"

  WebSocket {
    id: ws
    active: false

    onErrorStringChanged: (errorString) => {
      if (errorString !== '') {
        mainWindow.displayToast('WebSocket error: ' + errorString)
      }
    }

    onStatusChanged: (status) => {
                       if (status === WebSocket.Open) {
                           const event = JSON.stringify({"type": plugin.qchat_message_type_newcomer, "newcomer": qchatSettings.lastUserName})
                           sendTextMessage(event);
                         }
                       }

    onTextMessageReceived: (message) => {
                             const event = JSON.parse(message);
                             console.log(event.type);
                             switch (event.type) {
                               case plugin.qchat_message_type_text:
                               case plugin.qchat_message_type_image:
                               case plugin.qchat_message_type_bbox:
                                 historyModel.append({"historyType": event.type, "historyData": event});
                                 break;
                               case plugin.qchat_message_type_nb_users:
                                 detailsDialog.title = "<b>#" + qchatSettings.lastRoom + "</b>, " + qsTr("%n user(s)", "", event.nb_users) + " - QChat";
                                 break;
                               default:
                                 console.log(message);
                                 break;
                             }
                           }
  }

  Image {
    id: grabImage
    visible: false

    onStatusChanged: {
      if (status == Image.Ready && source !== undefined) {
        grabCanvas.requestPaint();
        let ctx = grabCanvas.getContext("2d");
        ctx.drawImage(grabImage, 0, 0);

        const event = JSON.stringify({"type": plugin.qchat_message_type_image, "author": qchatSettings.lastUserName, "avatar": "", "image_data": grabCanvas.toDataURL("image/png").substring(22)})
        ws.sendTextMessage(event);
      }
    }
  }

  Canvas {
    id: grabCanvas
    parent: mapCanvas
    visible: false
    x: 0
    y: 0
    width: mapCanvas.width
    height: mapCanvas.height
  }

  QfToolButtonDrawer {
    id: pluginButton
    iconSource: Qt.resolvedUrl("resources/img/geotribu.png")
    iconColor: "transparent"
    bgcolor: Theme.darkGray
    round: true

    QfToolButton {
      iconSource: Qt.resolvedUrl("resources/img/chat.svg")
      iconColor: ws.status == WebSocket.Open ? Theme.mainColor : "white"
      bgcolor: Theme.darkGraySemiOpaque
      width: 40
      height: 40
      padding: 0
      round: true

      onClicked: {
        if (ws.status != WebSocket.Open) {
          connectionDialog.open()
        } else {
          detailsDialog.open()
        }
      }
    }

    QfToolButton {
      iconSource: Qt.resolvedUrl("resources/img/news.svg")
      iconColor: "white"
      bgcolor: Theme.darkGraySemiOpaque
      width: 40
      height: 40
      padding: 0
      round: true

      onClicked: {
        Qt.openUrlExternally("https://geotribu.fr/")
      }
    }
  }
}
