import QtQuick
import QtQuick.Layouts
import app.loaf

ColumnLayout {
    id: root

    property string searchQuery: ""

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

    readonly property bool matchSmb: matches("network smb samba nas share server mount connect remote windows keyring")
    readonly property int matchCount: matchSmb ? 1 : 0

    readonly property var profiles: {
        if (typeof core !== "undefined" && core && core.smb_profiles_json) {
            try {
                return JSON.parse(core.smb_profiles_json || "[]");
            } catch (e) {
                return [];
            }
        }
        return [];
    }

    Layout.fillWidth: true
    spacing: 16

    SettingCard {
        visible: root.matchSmb
        title: qsTr("Network Storage (SMB / CIFS)")
        subtitle: qsTr("Connect to remote Windows file shares, home NAS, and Samba servers")
        icon: "network"

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: qsTr("Configured Shares")
                color: theme.textMain
                font.pixelSize: theme.fs(13)
                font.bold: true
                Layout.fillWidth: true
            }

            LoafButton {
                text: qsTr("Add Share")
                icon: "plus"
                variant: "filled"
                onClicked: if (typeof window !== "undefined") window.openSmbEditor({})
            }
        }

        SettingDivider {}

        Text {
            visible: root.profiles.length === 0
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: theme.textMuted
            font.pixelSize: theme.fs(12)
            text: qsTr("No shares saved yet. Add a server host and share name to connect. Mounted shares appear directly in the sidebar navigation and browse identically to local folders.")
        }

        Repeater {
            model: root.profiles

            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                implicitHeight: shareRow.implicitHeight + 20
                radius: theme.radiusM
                color: theme.surfaceContainerHigh
                border.width: 1
                border.color: theme.borderSubtle

                RowLayout {
                    id: shareRow
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    LoafIcon {
                        name: modelData.connected ? "network" : "plug"
                        size: 20
                        color: modelData.connected ? theme.primary : theme.textMuted
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 2

                        Text {
                            text: modelData.label || ""
                            color: theme.textMain
                            font.pixelSize: theme.fs(13)
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: (modelData.username ? modelData.username + "@" : "") + (modelData.server || "") + (modelData.share ? "/" + modelData.share : "")
                            color: theme.textMuted
                            font.pixelSize: theme.fs(11)
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }

                    LoafButton {
                        text: modelData.connected ? qsTr("Disconnect") : qsTr("Connect")
                        icon: modelData.connected ? "plug-slash" : "plug"
                        variant: modelData.connected ? "tonal" : "filled"
                        onClicked: {
                            if (typeof core !== "undefined" && core) {
                                if (modelData.connected)
                                    core.disconnect_smb(modelData.id);
                                else
                                    core.connect_smb(modelData.id, "", false);
                            }
                        }
                    }

                    LoafButton {
                        icon: "pencil-simple"
                        variant: "ghost"
                        Accessible.name: qsTr("Edit share")
                        onClicked: if (typeof window !== "undefined") window.openSmbEditor(modelData)
                    }

                    LoafButton {
                        icon: "trash"
                        variant: "ghost"
                        Accessible.name: qsTr("Remove share")
                        onClicked: if (typeof window !== "undefined") window.removeSmbShare(modelData.id, modelData.label)
                    }
                }
            }
        }
    }

    SettingCard {
        visible: root.matchSmb
        title: qsTr("Authentication & Mounting")
        subtitle: qsTr("Shares are mounted securely via GVfs. Credentials are saved in the system FreeDesktop secret keyring.")
        icon: "lock-key"
    }
}
