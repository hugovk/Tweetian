/*
    Copyright (C) 2012 Dickson Leong
    This file is part of Tweetian.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 1.1
import com.nokia.meego 1.0
import "../Component"
import "../Delegate"
import "../Utils/Database.js" as Database
import "../Services/Twitter.js" as Twitter

Item {
    implicitHeight: mainView.height; implicitWidth: mainView.width

    property string reloadType: "all"
    property ListModel fullModel: ListModel {}

    property bool busy: true
    property int unreadCount: 0

    // For DMThreadPage
    signal dmParsed(int newDMCount)
    signal dmRemoved(string id)

    onUnreadCountChanged: if (unreadCount === 0) harmattanUtils.clearNotification("tweetian.message")

    function initialize() {
        var msg = {
            type: "database",
            model: fullModel,
            threadModel: directMsgView.model,
            data: Database.getDMs()
        }
        dmParser.sendMessage(msg)
        busy = true
    }

    function insertNewDMs(receivedDM, sentDM) {
        var msg = {
            type: "newer",
            model: fullModel,
            threadModel: directMsgView.model,
            receivedDM: receivedDM,
            sentDM: sentDM
        }
        dmParser.sendMessage(msg)
        directMsgView.lastUpdate = new Date().toString()
    }

    function setDMThreadReaded(indexOrScreenName) {
        unreadCount = 0;
        var msg = { type: "setReaded", threadModel: directMsgView.model, index: -1 }
        switch (typeof indexOrScreenName) {
        case "number": msg.index = indexOrScreenName; break;
        case "string": msg.screenName = indexOrScreenName; break;
        default: throw new TypeError();
        }
        dmParser.sendMessage(msg)
    }

    function removeDM(id) {
        dmParser.sendMessage({type: "delete", model: fullModel, id: id})
        dmRemoved(id)
    }

    function removeAllDM() {
        var msg = {
            type: "all",
            model: fullModel,
            threadModel: directMsgView.model,
            receivedDM: [], sentDM: []
        }
        dmParser.sendMessage(msg)
    }

    function positionAtTop() {
        directMsgView.positionViewAtBeginning()
    }

    function refresh(type) {
        var sinceId = ""
        if (directMsgView.count > 0) {
            if (type === "newer") sinceId = fullModel.get(0).id
            else if (type === "all") directMsgView.model.clear()
        }
        else type = "all"
        reloadType = type
        Twitter.getDirectMsg(sinceId, "", internal.successCallback, internal.failureCallback)
        busy = true
    }

    PullDownListView {
        id: directMsgView
        anchors.fill: parent
        header: settings.enableStreaming ? streamingHeader : pullToRefreshHeader
        delegate: DMThreadDelegate {}
        model: ListModel {}
        onPulledDown: if (!userStream.connected) refresh("newer")

        Component { id: pullToRefreshHeader; PullToRefreshHeader {} }
        Component { id: streamingHeader; StreamingHeader {} }
    }

    Text {
        anchors.centerIn: parent
        visible: directMsgView.count == 0 && !busy
        font.pixelSize: constant.fontSizeXXLarge
        color: constant.colorMid
        text: qsTr("No message")
    }

    ScrollDecorator { flickableItem: directMsgView }

    Timer {
        id: refreshTimeStampTimer
        interval: 1 * 60 * 1000 // 1 minute
        repeat: true
        running: platformWindow.active
        triggeredOnStart: true
        onTriggered: if (directMsgView.count > 0) internal.refreshDMTime()
    }

    Timer {
        id: autoRefreshTimer
        interval: settings.directMsgRefreshFreq * 60000
        repeat: true
        running: networkMonitor.online && !settings.enableStreaming
        onTriggered: refresh("newer")
    }

    WorkerScript {
        id: dmParser
        source: "../WorkerScript/DMParser.js"
        onMessage: internal.onParseComplete(messageObject.type, messageObject.newDMCount,
                                            messageObject.showNotification)
    }

    QtObject {
        id: internal

        function refreshDMTime() {
            dmParser.sendMessage({type: "time", threadModel: directMsgView.model})
        }

        function successCallback(dmRecieve, dmSent) {
            var msg = {
                type: reloadType,
                model: fullModel,
                threadModel: directMsgView.model,
                receivedDM: dmRecieve,
                sentDM: dmSent
            }
            dmParser.sendMessage(msg)
            if (autoRefreshTimer.running) autoRefreshTimer.restart()
        }

        function failureCallback(status, statusText) {
            infoBanner.showHttpError(status, statusText)
            busy = false
        }

        function onParseComplete(type, newDMCount, showNotification) {
            if (type === "newer") {
                if (showNotification) {
                    unreadCount += newDMCount
                    if (settings.messageNotification) {
                        var body = qsTr("%n new message(s)", "", unreadCount)
                        if (!platformWindow.active) {
                            harmattanUtils.clearNotification("tweetian.message")
                            harmattanUtils.publishNotification("tweetian.message", "Tweetian", body, unreadCount)
                        }
                        else if (mainPage.status !== PageStatus.Active) {
                            infoBanner.showText(body)
                        }
                    }
                }
                busy = false
                dmParsed(newDMCount)
            }
            else if (type === "all") {
                busy = false
            }
            else if (type === "database") {
                if (fullModel.count > 0) {
                    directMsgView.lastUpdate = Database.getSetting("directMsgLastUpdate")
                    refresh("newer")
                }
                else refresh("all")
            }
        }
    }

    Component.onDestruction: {
        Database.setSetting({"directMsgLastUpdate": directMsgView.lastUpdate})
        Database.storeDMs(fullModel)
    }
}
