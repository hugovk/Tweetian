import QtQuick 1.1
import com.nokia.meego 1.0
import "../Delegate"
import "../twitter.js" as Twitter

AbstractUserPage{
    id: userFavouritesPage

    headerText: "Favourites"
    headerNumber: userInfoData.favouritesCount
    emptyText: "No favourite"
    loadMoreButtonVisible: listView.count > 0 && listView.count % 50 === 0
    delegate: TweetDelegate{}

    onReload: {
        var maxId = ""
        if(reloadType === "all") listView.model.clear()
        else maxId = listView.model.get(listView.count - 1).tweetId

        Twitter.getUserFavourites(userInfoData.screenName, maxId,
        function(data){
            backButtonEnabled = false
            userFavouritesParser.sendMessage({'model': listView.model, 'data': data, 'reloadType': reloadType})
        },
        function(status, statusText){
            if(status === 0) infoBanner.alert("Connection error.")
            else infoBanner.alert("Error: " + status + " " + statusText)
            loadingRect.visible = false
        })
        loadingRect.visible = true
    }

    WorkerScript{
        id: userFavouritesParser
        source: "../WorkerScript/TimelineParser.js"
        onMessage: {
            backButtonEnabled = true
            loadingRect.visible = false
        }
    }
}