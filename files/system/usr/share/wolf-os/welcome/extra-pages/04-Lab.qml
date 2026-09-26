// Wolf Welcome: the Wolf Lab.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.welcome as Welcome

Welcome.Page {
    heading: "The Wolf Lab"
    description: "Kali Linux's top hacking tools (nmap, Metasploit, Burp Suite, Wireshark and more) live in a container, not on your system. Your main system stays clean, and the tools stay up to date. Only test systems you own or have permission to test."

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            source: "utilities-terminal"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.gridUnit * 6
            Layout.preferredHeight: Kirigami.Units.gridUnit * 6
        }
        QQC2.Button {
            Layout.alignment: Qt.AlignHCenter
            text: "Open the Wolf Lab"
            icon.name: "utilities-terminal"
            onClicked: Welcome.Controller.runCommand("konsole -e /usr/bin/wolf lab")
        }
        QQC2.Label {
            Layout.alignment: Qt.AlignHCenter
            text: "The first time downloads a few GB. Later, just type: wolf lab"
            opacity: 0.7
        }
    }
}
