import QtQuick
import QtQuick.Layouts
import app.loaf

ColumnLayout {
    id: root

    property string searchQuery: ""

    property string repoDescription: qsTr("A beautiful and fast Rust-based Material 3 Expressive file manager for Linux.")
    property var contributors: []
    property bool contributorsLoading: false
    property string contributorsError: ""

    readonly property bool isCompact: (typeof settingsView !== "undefined" && settingsView.isCompact) || root.width < 560
    readonly property string repoUrl: "https://github.com/m-uvex/loaf-fm"

    function matches(keywords) {
        if (!searchQuery || searchQuery.length === 0) return true;
        var q = searchQuery.toLowerCase().trim();
        var parts = q.split(/\s+/);
        var kw = keywords.toLowerCase();
        for (var i = 0; i < parts.length; ++i) {
            if (parts[i].length > 0 && kw.indexOf(parts[i]) === -1) {
                return false;
            }
        }
        return true;
    }

    readonly property bool matchAbout: matches("about loaf version credits github contributors license repo description")
    readonly property bool matchContributors: matches("contributors people team authors credits github")
    readonly property int matchCount: (matchAbout ? 1 : 0) + (matchContributors ? 1 : 0)

    // Pulls the live repository description and contributor list so the
    // About tab stays accurate without shipping a new release.
    Timer {
        id: requestTimeout
        interval: 8000
        repeat: false
        onTriggered: {
            if (!root.contributorsLoading)
                return;
            root.contributorsLoading = false;
            root.contributorsError = qsTr("Could not reach GitHub. Check your connection and refresh.");
        }
    }

    function refreshRepository() {
        if (root.contributorsLoading)
            return;
        root.contributorsLoading = true;
        root.contributorsError = "";
        requestTimeout.restart();

        var repo = new XMLHttpRequest();
        repo.onreadystatechange = function() {
            if (repo.readyState !== XMLHttpRequest.DONE)
                return;
            if (repo.status === 200) {
                try {
                    var info = JSON.parse(repo.responseText);
                    if (info && typeof info.description === "string" && info.description.length > 0)
                        root.repoDescription = info.description;
                } catch (e) { /* keep bundled description */ }
            }
        };
        repo.open("GET", "https://api.github.com/repos/m-uvex/loaf-fm");
        repo.setRequestHeader("Accept", "application/vnd.github+json");
        repo.send();

        var people = new XMLHttpRequest();
        people.onreadystatechange = function() {
            if (people.readyState !== XMLHttpRequest.DONE)
                return;
            requestTimeout.stop();
            root.contributorsLoading = false;
            if (people.status === 200) {
                try {
                    var list = JSON.parse(people.responseText);
                    var out = [];
                    if (Array.isArray(list)) {
                        for (var i = 0; i < list.length; ++i) {
                            var c = list[i];
                            if (!c || !c.login || /\[bot\]$/.test(c.login))
                                continue;
                            out.push({
                                login: c.login,
                                avatar: c.avatar_url || "",
                                contributions: c.contributions || 0
                            });
                        }
                    }
                    root.contributors = out;
                } catch (e) {
                    root.contributorsError = qsTr("Could not read the contributor list.");
                }
            } else {
                root.contributorsError = qsTr("Contributors need an internet connection.");
            }
        };
        people.open("GET", "https://api.github.com/repos/m-uvex/loaf-fm/contributors?per_page=100");
        people.setRequestHeader("Accept", "application/vnd.github+json");
        people.send();
    }

    Component.onCompleted: refreshRepository()

    Layout.fillWidth: true
    spacing: 16

    // ---- Hero identity card -------------------------------------------
    Rectangle {
        visible: root.matchAbout
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        radius: theme.radiusXl
        color: theme.surfaceContainer
        border.width: 1
        border.color: theme.borderSubtle
        implicitHeight: heroCol.implicitHeight + (root.isCompact ? 36 : 56)

        Behavior on color { enabled: theme.animate; ColorAnimation { duration: theme.durationNormal } }

        ColumnLayout {
            id: heroCol
            anchors.fill: parent
            anchors.margins: root.isCompact ? 18 : 28
            spacing: root.isCompact ? 14 : 18

            // Icon + wordmark, centred as one unit.
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: root.isCompact ? 14 : 18

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    width: root.isCompact ? 60 : 72
                    height: width
                    radius: width * 0.28
                    color: theme.primaryContainer
                    border.width: 2
                    border.color: theme.primary

                    LoafIcon {
                        anchors.centerIn: parent
                        name: "bread"
                        size: root.isCompact ? 32 : 38
                        color: theme.primaryContainerFg
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Loaf"
                        color: theme.textMain
                        font.pixelSize: root.isCompact ? theme.fs(26) : theme.fs(32)
                        font.bold: true
                        font.letterSpacing: -0.8
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        radius: theme.radiusFull
                        color: theme.secondaryContainer
                        implicitHeight: 24
                        implicitWidth: verTxt.implicitWidth + 16

                        Text {
                            id: verTxt
                            anchors.centerIn: parent
                            text: qsTr("Version ") + Qt.application.version
                            color: theme.secondaryContainerFg
                            font.pixelSize: theme.fs(11)
                            font.bold: true
                        }
                    }
                }
            }

            // Repository description (mirrors the GitHub repo blurb).
            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: root.repoDescription
                color: theme.textMuted
                font.pixelSize: theme.fs(13)
                lineHeight: 1.2
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
            }

            // Actions, one column on narrow layouts.
            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                columns: root.isCompact ? 1 : 2
                columnSpacing: 10
                rowSpacing: 10

                LoafButton {
                    text: qsTr("Repository")
                    icon: "github-logo"
                    variant: "filled"
                    Layout.fillWidth: root.isCompact
                    onClicked: Qt.openUrlExternally(root.repoUrl)
                }

                LoafButton {
                    text: qsTr("Report an issue")
                    icon: "bug"
                    variant: "tonal"
                    Layout.fillWidth: root.isCompact
                    onClicked: Qt.openUrlExternally(root.repoUrl + "/issues")
                }
            }
        }
    }

    // ---- Contributors --------------------------------------------------
    SettingCard {
        visible: root.matchContributors
        title: qsTr("Contributors")
        subtitle: qsTr("Everyone who has landed code in the repository, pulled live from GitHub")
        icon: "users"

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: root.contributorsLoading
                    ? qsTr("Loading contributors…")
                    : (root.contributors.length > 0
                        ? theme.plural(root.contributors.length, qsTr("1 contributor"), qsTr("%1 contributors"))
                        : (root.contributorsError.length > 0 ? root.contributorsError : qsTr("No contributors listed yet.")))
                color: theme.textMuted
                font.pixelSize: theme.fs(12)
                wrapMode: Text.Wrap
            }

            LoafButton {
                text: qsTr("Refresh")
                icon: "arrow-clockwise"
                variant: "tonal"
                enabled: !root.contributorsLoading
                onClicked: root.refreshRepository()
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: root.contributors

                delegate: Rectangle {
                    required property var modelData

                    width: contributorRow.implicitWidth + 20
                    height: 34
                    radius: theme.radiusFull
                    color: contributorMouse.containsMouse ? theme.primaryContainer : theme.surfaceContainerHigh
                    border.width: 1
                    border.color: contributorMouse.containsMouse ? theme.primary : theme.borderSubtle

                    Behavior on color { enabled: theme.animate; ColorAnimation { duration: theme.durationFast } }
                    Behavior on border.color { enabled: theme.animate; ColorAnimation { duration: theme.durationFast } }

                    Accessible.role: Accessible.Link
                    Accessible.name: modelData.login

                    RowLayout {
                        id: contributorRow
                        anchors.centerIn: parent
                        spacing: 7

                        Item {
                            width: 22
                            height: 22

                            // Letter avatar: always available, even offline.
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: theme.surfaceContainerHighest

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.login ? modelData.login.charAt(0).toUpperCase() : "?"
                                    color: theme.textMuted
                                    font.pixelSize: theme.fs(10)
                                    font.bold: true
                                }
                            }

                            // Live GitHub avatar, cropped into the chip.
                            Image {
                                anchors.fill: parent
                                source: modelData.avatar || ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                sourceSize.width: 44
                                sourceSize.height: 44
                                visible: status === Image.Ready
                            }
                        }

                        Text {
                            text: modelData.login
                            color: contributorMouse.containsMouse ? theme.primaryContainerFg : theme.textMain
                            font.pixelSize: theme.fs(11)
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: contributorMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally(root.repoUrl + "/graphs/contributors")
                    }
                }
            }
        }

        Text {
            visible: root.contributors.length === 0 && !root.contributorsLoading
            Layout.fillWidth: true
            text: qsTr("Contributor avatars load from GitHub. Connect to the internet and refresh to populate this list.")
            color: theme.textMuted
            font.pixelSize: theme.fs(11)
            wrapMode: Text.Wrap
        }
    }
}
