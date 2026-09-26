// Wolf Welcome: what makes Wolf OS different.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.welcome as Welcome

Welcome.Page {
    heading: "What makes Wolf OS different"
    description: "Everything below is already on. You control it all from the wolf icon next to the clock, or with the wolf command in Howl (type: wolf help)."

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width, Kirigami.Units.gridUnit * 34)
        spacing: Kirigami.Units.largeSpacing * 2

        Repeater {
            model: [
                ["security-high", "Secure by default", "Firewall, hardened kernel, signed updates and full-disk encryption. Check your score any time: wolf check"],
                ["network-wireless", "Networks that know who to trust", "New Wi-Fi networks start as public, so other people there can't see or probe this PC. Mark your home network trusted with one click."],
                ["input-gaming", "Gaming and security in one OS", "Steam, Heroic and Lutris are one command away, and Game Mode opens what games need only while you play."],
                ["utilities-terminal", "A hacking lab that stays in its box", "Kali's top tools live in a container, not on your system: wolf lab"],
                ["edit-undo", "Updates that can't break it", "The whole system updates at once. If an update ever misbehaves, pick the previous version in the boot menu."]
            ]
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing
                Kirigami.Icon {
                    source: modelData[0]
                    Layout.preferredWidth: Kirigami.Units.iconSizes.large
                    Layout.preferredHeight: Kirigami.Units.iconSizes.large
                    Layout.alignment: Qt.AlignTop
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Kirigami.Heading {
                        text: modelData[1]
                        level: 4
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: modelData[2]
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
