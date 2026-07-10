pragma Translator: QfChat

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebSockets
import QtCore

import org.qfield
import org.qgis
import Theme

import "qrc:/qml" as QFieldItems

Item {
    id: plugin
    objectName: "plugin"

    property var mainWindow: iface.mainWindow()
    property var mapCanvas: iface.mapCanvas()

    property bool qchatMinimized: false
    property var qchatLastMessage: null

    Settings {
        id: qchatSettings
        property string lastUrl: "https://qchat.geotribu.net"
        property string lastChannel: "QGIS"
        property string lastUserName: "jd_" + (Math.random * 10000)
        property string lastAvatar: "mIconXyz.svg"
    }

    Component.onCompleted: {
        userNameInput.text = qchatSettings.lastUserName;
        serverUrlField.text = qchatSettings.lastUrl;
        serverChannelField.text = qchatSettings.lastChannel;

        iface.addItemToPluginsToolbar(pluginButton);
    }

    Dialog {
        id: connectionDialog
        title: qsTranslate("QfChat", "Connection - QChat")
        focus: true
        font: Theme.defaultFont
        parent: mainWindow.contentItem

        x: (mainWindow.width - width) / 2
        y: (mainWindow.height - height - 80) / 2

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 360
                easing.type: Easing.OutCubic
            }
        }
        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: 160
                easing.type: Easing.InCubic
            }
        }

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
                text: qsTranslate("QfChat", "Pick a server, a channel, and enter your nickname below.")
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
                    let servers = ["https://qchat.geotribu.net"];
                    if (qchatSettings.lastUrl != "" && servers.indexOf(qchatSettings.lastUrl) < 0) {
                        servers.push(qchatSettings.lastUrl);
                    }
                    return servers;
                }

                contentItem: TextField {
                    id: serverUrlField

                    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase
                    enabled: ws.status == WebSocket.Closed
                    font: Theme.defaultFont
                    text: parent.displayText
                    placeholderText: qsTranslate("QfChat", "Server")

                    onTextChanged: {
                        getChannelsTimer.restart();
                    }
                }

                background: Rectangle {
                    color: "transparent"
                }

                Component.onCompleted: {
                    currentIndex = find(qchatSettings.lastUrl);
                    getChannelsTimer.restart();
                }

                onModelChanged: {
                    currentIndex = find(qchatSettings.lastUrl);
                }

                onDisplayTextChanged: {
                    serverUrlField.text = displayText;
                }
            }

            ComboBox {
                id: serverChannelComboBox
                width: connectionLabel.width
                font: Theme.defaultFont
                editable: true
                enabled: ws.status == WebSocket.Closed
                model: []

                contentItem: TextField {
                    id: serverChannelField

                    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase
                    enabled: ws.status == WebSocket.Closed
                    font: Theme.defaultFont
                    text: parent.displayText
                    placeholderText: qsTranslate("QfChat", "Channel")
                }

                background: Rectangle {
                    color: "transparent"
                }

                Component.onCompleted: {
                    currentIndex = find(qchatSettings.lastChannel);
                }

                onModelChanged: {
                    currentIndex = find(qchatSettings.lastChannel);
                }

                onDisplayTextChanged: {
                    serverChannelField.text = displayText;
                }
            }

            TextField {
                id: userNameInput
                width: connectionLabel.width
                font: Theme.defaultFont
                enabled: ws.status == WebSocket.Closed
                placeholderText: qsTranslate("QfChat", "User name")
            }

            ComboBox {
                id: avatarComboBox
                width: connectionLabel.width
                font: Theme.defaultFont
                enabled: ws.status == WebSocket.Closed
                model: qchatAvatarChoices
                textRole: "label"

                contentItem: Row {
                    spacing: 6
                    leftPadding: 4

                    Image {
                        width: 16
                        height: 16
                        anchors.verticalCenter: parent.verticalCenter
                        source: avatarComboBox.currentIndex >= 0 ? Qt.resolvedUrl("resources/img/avatars/") + qchatAvatarChoices[avatarComboBox.currentIndex].value : ""
                        fillMode: Image.PreserveAspectFit
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        font: Theme.defaultFont
                        color: Theme.mainTextColor
                        text: avatarComboBox.currentIndex >= 0 ? qchatAvatarChoices[avatarComboBox.currentIndex].label : ""
                    }
                }

                delegate: ItemDelegate {
                    width: avatarComboBox.width
                    highlighted: avatarComboBox.highlightedIndex === index

                    contentItem: Row {
                        spacing: 6

                        Image {
                            width: 16
                            height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            source: Qt.resolvedUrl("resources/img/avatars/") + modelData.value
                            fillMode: Image.PreserveAspectFit
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            font: Theme.defaultFont
                            color: highlighted ? Theme.mainColor : Theme.mainTextColor
                            text: modelData.label
                        }
                    }
                }

                background: Rectangle {
                    color: "transparent"
                }

                Component.onCompleted: {
                    for (let i = 0; i < qchatAvatarChoices.length; i++) {
                        if (qchatAvatarChoices[i].value === qchatSettings.lastAvatar) {
                            currentIndex = i;
                            break;
                        }
                    }
                }
            }
        }

        standardButtons: Dialog.Ok | Dialog.Close

        onAccepted: {
            ws.active = false;
            const websocketProtocol = serverUrlField.text.trim().startsWith("https") ? "wss" : "ws";
            const serverUrl = serverUrlField.text.trim().replace("https://", "").replace("http://", "");
            ws.url = websocketProtocol + "://" + serverUrl + "/channel/" + serverChannelField.text.trim() + "/ws";
            ws.active = true;

            qchatSettings.lastUserName = userNameInput.text.trim();
            qchatSettings.lastChannel = serverChannelField.text.trim();
            qchatSettings.lastUrl = serverUrlField.text.trim();
            qchatSettings.lastAvatar = qchatAvatarChoices[avatarComboBox.currentIndex].value;
        }

        Component.onCompleted: {
            standardButton(Dialog.Ok).text = qsTranslate("QfChat", "Connect");
        }

        Timer {
            id: getChannelsTimer
            interval: 500
            repeat: false
            running: false

            onTriggered: {
                connectionDialog.getChannels();
            }
        }

        function getChannels() {
            const url = serverUrlField.text.trim() + "/channels";
            let request = new XMLHttpRequest();

            request.onreadystatechange = function () {
                if (request.readyState === XMLHttpRequest.DONE) {
                    let responseArray = JSON.parse(request.response);
                    serverChannelComboBox.model = responseArray;
                }
            };

            request.open("GET", url);
            request.send();
        }
    }

    Dialog {
        id: qchatMainDialog
        title: qsTranslate("QfChat", "QChat")
        focus: true
        font: Theme.defaultFont
        parent: mainWindow.contentItem

        x: (mainWindow.width - width) / 2
        y: (mainWindow.height - height - 80) / 2

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 360
                easing.type: Easing.OutCubic
            }
        }
        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: 160
                easing.type: Easing.InCubic
            }
        }

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
                    ScrollBar.vertical: QfScrollBar {}
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
                                historyView.ScrollBar.vertical.position = historyView.contentHeight;
                            }

                            width: parent.width

                            Column {
                                width: parent.width
                                spacing: 2

                                Row {
                                    width: parent.width
                                    spacing: 4

                                    Image {
                                        width: historyData.avatar ? 16 : 0
                                        height: 16
                                        anchors.verticalCenter: parent.verticalCenter
                                        source: historyData.avatar ? Qt.resolvedUrl("resources/img/avatars/") + historyData.avatar : ""
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    Label {
                                        width: parent.width - (historyData.avatar ? 20 : 0)
                                        font: Theme.tipFont
                                        color: Theme.secondaryTextColor
                                        wrapMode: Text.WordWrap
                                        text: {
                                            const messageTime = new Date(historyData.timestamp).toLocaleTimeString({
                                                hour: "2-digit",
                                                minute: "2-digit",
                                                second: "2-digit"
                                            });
                                            switch (historyType) {
                                            case plugin.qchat_message_type_text:
                                            case plugin.qchat_message_type_image:
                                            case plugin.qchat_message_type_bbox:
                                            case plugin.qchat_message_type_position:
                                                return "<i>" + qsTranslate("QfChat", "%1").arg(historyData.author) + "</i> (" + messageTime + "):";
                                            }
                                            return "";
                                        }
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
                                    height: historyType == plugin.qchat_message_type_image ? 100 : 0
                                    source: historyType == plugin.qchat_message_type_image ? "data:image/png;base64," + historyData.image_data : ""
                                    fillMode: Image.PreserveAspectFit

                                    onStatusChanged: {
                                        if (source !== "" && status == Image.Ready) {
                                            historyView.ScrollBar.vertical.position = historyView.contentHeight;
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
                                    text: qsTranslate("QfChat", "🔳 Zoom to extent")

                                    onClicked: {
                                        const wkt = "MULTIPOINT((" + historyData.xmin + " " + historyData.ymin + "),(" + historyData.xmax + " " + historyData.ymax + "))";
                                        const geom = GeometryUtils.createGeometryFromWkt(wkt);
                                        const bbox = GeometryUtils.boundingBox(geom);
                                        const bboxCrs = CoordinateReferenceSystemUtils.fromDescription(historyData.crs_authid);
                                        mapCanvas.mapSettings.extent = GeometryUtils.reprojectRectangle(bbox, bboxCrs, mapCanvas.mapSettings.destinationCrs);
                                    }
                                }

                                QfButton {
                                    visible: historyType == plugin.qchat_message_type_position
                                    width: parent.width
                                    borderColor: Theme.mainTextColor
                                    color: Theme.mainTextColor
                                    bgcolor: "transparent"
                                    text: qsTranslate("QfChat", "📍 Go to location")

                                    onClicked: {
                                        const point = GeometryUtils.point(historyData.x, historyData.y);
                                        const crs = CoordinateReferenceSystemUtils.fromDescription(historyData.crs_authid);
                                        const projectedPoint = GeometryUtils.reprojectPoint(point, crs, qgisProject.crs);
                                        mapCanvas.jumpTo(projectedPoint);
                                    }
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 10

                    Image {
                        width: 24
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter
                        source: qchatSettings.lastAvatar ? Qt.resolvedUrl("resources/img/avatars/") + qchatSettings.lastAvatar : ""
                        fillMode: Image.PreserveAspectFit
                    }

                    TextField {
                        id: messageInput
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 150
                        font: Theme.defaultFont
                        placeholderText: qsTranslate("QfChat", "Message content")
                    }

                    QfToolButton {
                        round: true
                        iconSource: "resources/img/send.svg"
                        iconColor: Theme.mainTextColor
                        bgcolor: "transparent"

                        onClicked: {
                            if (messageInput.text !== "") {
                                const event = JSON.stringify({
                                    "type": plugin.qchat_message_type_text,
                                    "author": qchatSettings.lastUserName,
                                    "avatar": qchatSettings.lastAvatar,
                                    "text": messageInput.text
                                });
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
                            mapCanvas.grabToImage(function (result) {
                                grabImage.source = result.url;
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
                    fillMode: Image.PreserveAspectFit
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

        footer: DialogButtonBox {
            Button {
                text: qsTranslate("QfChat", "Minimize")
                flat: true
                DialogButtonBox.buttonRole: DialogButtonBox.ResetRole
                onClicked: {
                    plugin.qchatMinimized = true;
                    qchatMainDialog.close();
                }
            }
            Button {
                text: qsTranslate("QfChat", "Disconnect")
                flat: true
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            }
            Button {
                text: qsTranslate("QfChat", "Close")
                flat: true
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            }
        }

        onAccepted: {
            const event = JSON.stringify({
                "type": plugin.qchat_message_type_exiter,
                "exiter": qchatSettings.lastUserName
            });
            ws.sendTextMessage(event);
            ws.active = false;
            historyModel.clear();
            plugin.qchatMinimized = false;
            plugin.qchatLastMessage = null;
            connectionDialog.open();
        }
    }

    Rectangle {
        id: minimizedBar
        parent: mainWindow.contentItem

        visible: plugin.qchatMinimized && !connectionDialog.visible && !qchatMainDialog.visible

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 88 + 10 // a bit of place for the scale widget
        anchors.rightMargin: 48 + 10 // 48 = tool button size (location button) + 5 x 2 spacing
        anchors.bottomMargin: -height // start below the canvas to make the transition smoother
        height: 48 // tool button height
        z: 1
        radius: 8
        color: Theme.mainBackgroundColor
        border.width: 1
        border.color: Theme.mainColor

        function getBottomMargin() {
            const osNavBarHeight = mainWindow.sceneBottomMargin;
            const featureForm = iface.findItemByObjectName("featureForm");
            if (!featureForm.visible) {
                return osNavBarHeight + 10;
            }
            return parent.height - featureForm.y + 10;
        }

        states: State {
            name: "shown"
            when: plugin.qchatMinimized && !connectionDialog.visible && !qchatMainDialog.visible
            PropertyChanges {
                target: minimizedBar
                anchors.bottomMargin: getBottomMargin()
            }
        }

        transitions: [
            Transition {
                from: ""
                to: "shown"
                NumberAnimation {
                    property: "anchors.bottomMargin"
                    duration: 360
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.1
                }
            },
            Transition {
                from: "shown"
                to: ""
                NumberAnimation {
                    property: "anchors.bottomMargin"
                    duration: 200
                    easing.type: Easing.InBack
                    easing.overshoot: 0.8
                }
            }
        ]

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 16
                rightMargin: 8
            }
            spacing: 8

            Image {
                width: 16
                height: 16
                Layout.alignment: Qt.AlignVCenter
                source: {
                    const last_message = plugin.qchatLastMessage;
                    if (last_message && last_message.avatar)
                        return Qt.resolvedUrl("resources/img/avatars/") + last_message.avatar;
                    return "";
                }
                fillMode: Image.PreserveAspectFit
            }

            Label {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                font: Theme.defaultFont
                color: Theme.mainTextColor
                elide: Text.ElideRight
                text: {
                    const last_message = plugin.qchatLastMessage;
                    if (!last_message)
                        return qsTranslate("QfChat", "QChat");
                    if (last_message.type === plugin.qchat_message_type_image)
                        return (last_message.author || "") + ": " + qsTranslate("QfChat", "[image sent]");
                    if (last_message.type === plugin.qchat_message_type_text)
                        return (last_message.author || "") + ": " + (last_message.text || "");
                    if (last_message.type === plugin.qchat_message_type_bbox)
                        return (last_message.author || "") + ": " + qsTranslate("QfChat", "[extent]");
                    if (last_message.type === plugin.qchat_message_type_position)
                        return (last_message.author || "") + ": " + qsTranslate("QfChat", "[location]");
                    return qsTranslate("QfChat", "QChat - no message");
                }
            }

            QfToolButton {
                Layout.alignment: Qt.AlignVCenter
                width: 48
                height: 48
                round: true
                iconSource: Qt.resolvedUrl("resources/img/chat.svg")
                iconColor: Theme.mainTextColor
                bgcolor: "transparent"
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: plugin.qchatMinimized
            onClicked: {
                plugin.qchatMinimized = false;
                qchatMainDialog.open();
            }
        }
    }

    readonly property var qchatAvatarChoices: [
        {
            label: "Arrow Up",
            value: "mActionArrowUp.svg"
        },
        {
            label: "CAD",
            value: "cadtools/cad.svg"
        },
        {
            label: "Calculate",
            value: "mActionCalculateField.svg"
        },
        {
            label: "Camera",
            value: "mIconCamera.svg"
        },
        {
            label: "Certificate",
            value: "mIconCertificate.svg"
        },
        {
            label: "Comment",
            value: "mIconInfo.svg"
        },
        {
            label: "Compressed",
            value: "mIconZip.svg"
        },
        {
            label: "Folder",
            value: "mIconFolder.svg"
        },
        {
            label: "GeoPackage",
            value: "mGeoPackage.svg"
        },
        {
            label: "GPU",
            value: "mIconGPU.svg"
        },
        {
            label: "HTML",
            value: "mActionAddHtml.svg"
        },
        {
            label: "Information",
            value: "mActionPropertiesWidget.svg"
        },
        {
            label: "Network Logger",
            value: "mIconNetworkLogger.svg"
        },
        {
            label: "Postgis",
            value: "mIconPostgis.svg"
        },
        {
            label: "Python",
            value: "mIconPythonFile.svg"
        },
        {
            label: "Pyramid",
            value: "mIconPyramid.svg"
        },
        {
            label: "Raster",
            value: "mIconRaster.svg"
        },
        {
            label: "Spatialite",
            value: "mIconSpatialite.svg"
        },
        {
            label: "Tooltip",
            value: "mActionMapTips.svg"
        },
        {
            label: "XYZ",
            value: "mIconXyz.svg"
        }
    ]

    function avatarLabel(avatarValue) {
        if (!avatarValue)
            return "";
        for (let i = 0; i < qchatAvatarChoices.length; i++) {
            if (qchatAvatarChoices[i].value === avatarValue)
                return qsTranslate("QfChat", qchatAvatarChoices[i].label);
        }
        return qsTranslate("QfChat", "XYZ");
    }

    readonly property string qchat_message_type_bbox: "bbox"
    readonly property string qchat_message_type_crs: "crs"
    readonly property string qchat_message_type_exiter: "exiter"
    readonly property string qchat_message_type_geojson: "geojson"
    readonly property string qchat_message_type_image: "image"
    readonly property string qchat_message_type_like: "like"
    readonly property string qchat_message_type_nb_users: "nb_users"
    readonly property string qchat_message_type_newcomer: "newcomer"
    readonly property string qchat_message_type_position: "position"
    readonly property string qchat_message_type_text: "text"
    readonly property string qchat_message_type_uncompliant: "uncompliant"

    readonly property var qchat_cheatcodes: ["givemesomecheese", "lookattheflickofqgis", "iamarobot", "its10oclock", "qgisprolicense", "wizz", "spaceandtime",]

    WebSocket {
        id: ws
        active: false

        onErrorStringChanged: errorString => {
            if (errorString !== '') {
                mainWindow.displayToast('WebSocket error: ' + errorString);
            }
        }

        onStatusChanged: status => {
            if (status === WebSocket.Open) {
                const event = JSON.stringify({
                    "type": plugin.qchat_message_type_newcomer,
                    "newcomer": qchatSettings.lastUserName
                });
                sendTextMessage(event);
                qchatMainDialog.open();
            }
        }

        function handleCheatCode(message) {
            switch (message.text) {
            case "qgisprolicense":
                mainWindow.displayToast(qsTranslate("QfChat", "Your QField pro license is about to expire. Consider renewing it !"));
                break;
            case "wizz":
                // make the device vibrate for 1 second
                platformUtilities.vibrate(1000);
                break;
            default:
                break;
            }
        }

        onTextMessageReceived: message => {
            const event = JSON.parse(message);
            switch (event.type) {
            case plugin.qchat_message_type_text:
                if (plugin.qchat_cheatcodes.includes(event.text)) {
                    handleCheatCode(event);
                    break;
                }
                if (event.text.includes("@" + qchatSettings.lastUserName) || event.text.includes("@all")) {
                    mainWindow.displayToast(qsTranslate("QfChat", "QChat mention by %1: '%2'").arg(event.author).arg(event.text));
                }
            case plugin.qchat_message_type_image:
            case plugin.qchat_message_type_position:
            case plugin.qchat_message_type_bbox:
                historyModel.append({
                    "historyType": event.type,
                    "historyData": event
                });
                plugin.qchatLastMessage = {
                    "type": event.type,
                    "author": event.author || "",
                    "avatar": event.avatar || "",
                    "text": event.text || ""
                };
                break;
            case plugin.qchat_message_type_nb_users:
                qchatMainDialog.title = "<b>#" + qchatSettings.lastChannel + "</b>, " + qsTranslate("QfChat", "%n user(s)", "", event.nb_users) + " - QChat";
                break;
            default:
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

                const event = JSON.stringify({
                    "type": plugin.qchat_message_type_image,
                    "author": qchatSettings.lastUserName,
                    "avatar": qchatSettings.lastAvatar,
                    "image_data": grabCanvas.toDataURL("image/png").substring(22)
                });
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
        objectName: "pluginButton"
        iconSource: Qt.resolvedUrl("resources/img/qchat.svg")
        iconColor: "transparent"
        bgcolor: Theme.darkGray
        round: true

        QfToolButton {
            objectName: "pluginQChatButton"
            iconSource: Qt.resolvedUrl("resources/img/chat.svg")
            iconColor: ws.status == WebSocket.Open ? Theme.mainColor : "white"
            bgcolor: Theme.darkGraySemiOpaque
            width: 40
            height: 40
            padding: 0
            round: true

            onClicked: {
                if (ws.status != WebSocket.Open) {
                    connectionDialog.open();
                } else {
                    qchatMainDialog.open();
                }
            }
        }

        QfToolButton {
            objectName: "pluginNewsButton"
            iconSource: Qt.resolvedUrl("resources/img/news.svg")
            iconColor: "white"
            bgcolor: Theme.darkGraySemiOpaque
            width: 40
            height: 40
            padding: 0
            round: true

            onClicked: {
                Qt.openUrlExternally("https://geotribu.fr/");
            }
        }
    }
}
