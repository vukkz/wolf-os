// Wolf Welcome: set up gaming.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.welcome as Welcome

Welcome.Page {
    heading: "Ready to play?"
    description: "One click installs Steam, Heroic (Epic, GOG, Amazon), Lutris (Battle.net, EA, Ubisoft) and ProtonUp-Qt, all sandboxed. Most Windows games run through Proton; check yours at protondb.com. Games with kernel anti-cheat (Valorant, League of Legends, Fortnite) don't run on any Linux."

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            source: "input-gaming"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.gridUnit * 6
            Layout.preferredHeight: Kirigami.Units.gridUnit * 6
        }
        QQC2.Button {
            Layout.alignment: Qt.AlignHCenter
            text: "Set up gaming"
            icon.name: "download"
            onClicked: Welcome.Controller.runCommand("konsole --hold -e /usr/bin/wolf setup gaming")
        }
        QQC2.Button {
            Layout.alignment: Qt.AlignHCenter
            text: "Check a game on ProtonDB"
            icon.name: "internet-web-browser"
            flat: true
            onClicked: Qt.openUrlExternally("https://www.protondb.com")
        }
        QQC2.Label {
            Layout.alignment: Qt.AlignHCenter
            text: "Before playing, turn on Game Mode from the wolf icon (or: wolf game on)."
            opacity: 0.7
        }
    }
}
