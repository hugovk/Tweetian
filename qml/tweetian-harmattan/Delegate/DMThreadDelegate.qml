import QtQuick 1.1
import com.nokia.meego 1.0

AbstractDelegate{
    id: root
    height: Math.max(textColumn.height, profileImage.height) + 2 * constant.paddingMedium
    sideRectColor: newMsg ? constant.colorTextSelection : ""

    Column{
        id: textColumn
        anchors{
            left: profileImage.right
            right: subIcon.left
            leftMargin: constant.paddingSmall
            top: parent.top
            topMargin: constant.paddingMedium
        }
        height: childrenRect.height

        Item{
            width: parent.width
            height: childrenRect.height

            Text{
                id: userNameText
                anchors.left: parent.left
                width: Math.min(implicitWidth, parent.width)
                text: userName
                font.pixelSize: settings.largeFontSize ? constant.fontSizeMedium : constant.fontSizeSmall
                font.bold: true
                color: highlighted ? constant.colorHighlighted : constant.colorLight
                elide: Text.ElideRight
            }

            Text{
                anchors{ left: userNameText.right; leftMargin: constant.paddingMedium; right: parent.right }
                text: "@" + screenName
                font.pixelSize: settings.largeFontSize ? constant.fontSizeMedium : constant.fontSizeSmall
                color: highlighted ? constant.colorHighlighted : constant.colorMid
                elide: Text.ElideRight
            }
        }

        Text{
            width: parent.width
            wrapMode: Text.Wrap
            font.pixelSize: settings.largeFontSize ? constant.fontSizeMedium : constant.fontSizeSmall
            color: highlighted ? constant.colorHighlighted : constant.colorLight
            text: tweetText
        }

        Text{
            width: parent.width
            horizontalAlignment: Text.AlignRight
            font.pixelSize: settings.largeFontSize ? constant.fontSizeSmall : constant.fontSizeXSmall
            color: highlighted ? constant.colorHighlighted : constant.colorMid
            text: timeDiff
        }
    }

    Image {
        id: subIcon
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: constant.paddingMedium
        source: "image://theme/icon-m-common-drilldown-arrow".concat(settings.invertedTheme ? "" : "-inverse")
        sourceSize.width: constant.graphicSizeSmall
        sourceSize.height: constant.graphicSizeSmall
        height: sourceSize.height
        width: sourceSize.width
    }

    onClicked: {
        if(newMsg) parser.setProperty(index, "newMsg", false)
        unreadCount = 0
        var prop = { screenName: screenName, userStream: userStream }
        pageStack.push(Qt.resolvedUrl("../MainPageCom/DMThreadPage.qml"), prop)
    }
}