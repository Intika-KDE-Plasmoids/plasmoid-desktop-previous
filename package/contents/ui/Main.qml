import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import "lib"

Item {
	id: widget

    // Updater 1/3 ==================================================================================================================================
    property string updateResponse;
    property string currentVersion: '6.0';
    property bool checkUpdateStartup: Plasmoid.configuration.checkUpdateStartup
    // ==============================================================================================================================================
    
    property var desktopCommand: 'NEXT=$(($(qdbus org.kde.KWin /KWin currentDesktop) - 1));MAX=$(wmctrl -d | wc -l);if [[ $NEXT -eq 0 ]]; then NEXT=$MAX; fi;NEXT=$(($NEXT - 1));wmctrl -r :ACTIVE: -t $NEXT; wmctrl -s $NEXT;'

	Plasmoid.onActivated: widget.activate()
	property bool disableLatteParabolicIcon: true // Don't hide the representation in Latte (https://github.com/psifidotos/Latte-Dock/issues/983)
	Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
	Plasmoid.fullRepresentation: Item {
		id: panelItem

		readonly property bool inPanel: (plasmoid.location == PlasmaCore.Types.TopEdge
			|| plasmoid.location == PlasmaCore.Types.RightEdge
			|| plasmoid.location == PlasmaCore.Types.BottomEdge
			|| plasmoid.location == PlasmaCore.Types.LeftEdge)

		Layout.minimumWidth: {
			switch (plasmoid.formFactor) {
			case PlasmaCore.Types.Vertical:
				return 0;
			case PlasmaCore.Types.Horizontal:
				return height;
			default:
				return units.gridUnit * 3;
			}
		}

		Layout.minimumHeight: {
			switch (plasmoid.formFactor) {
			case PlasmaCore.Types.Vertical:
				return width;
			case PlasmaCore.Types.Horizontal:
				return 0;
			default:
				return units.gridUnit * 3;
			}
		}

		Layout.maximumWidth: inPanel ? units.iconSizeHints.panel : -1
		Layout.maximumHeight: inPanel ? units.iconSizeHints.panel : -1

		AppletIcon {
			id: icon
			anchors.fill: parent

			source: plasmoid.configuration.icon
			active: mouseArea.containsMouse
		}

		MouseArea {
			id: mouseArea
			anchors.fill: parent
			hoverEnabled: true
			onClicked: widget.activate()
		}
	}
    
	PlasmaCore.DataSource {
		id: executable
		engine: "executable"
		connectedSources: []
		onNewData: disconnectSource(sourceName)

		function exec(cmd) {
			executable.connectSource(cmd)
		}
	}
    
	function activate() {
        executable.exec(desktopCommand);
	}
    
	function action_showDesktopGrid() {
		executable.exec('qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "ShowDesktopGrid"')
	}
    
    // Updater 2/3 ==================================================================================================================================
    
    PlasmaCore.DataSource {
        id: executableNotification
        engine: "executable"
        onNewData: disconnectSource(sourceName) // cmd finished
        function exec(cmd) {
            connectSource(cmd)
        }
    }
    
    Timer {
        id:timerStartUpdater
        interval: 300000
        onTriggered: updaterNotification(false)
    }
    
    function availableUpdate() {
        var notificationCommand = "notify-send --icon=remmina-panel 'Plasmoid Desktop Previous' 'An update is available \n<a href=\"https://www.opendesktop.org/p/1289593/\">Update link</a>' -t 30000";
        executableNotification.exec(notificationCommand);
    }

    function noAvailableUpdate() {
        var notificationCommand = "notify-send --icon=remmina-panel 'Plasmoid Desktop Previous' 'Your current version is up to date' -t 30000";
        executableNotification.exec(notificationCommand);
    }
    
    function updaterNotification(notifyUpdated) {
        var xhr = new XMLHttpRequest;
        xhr.responseType = 'text';
        xhr.open("GET", "https://raw.githubusercontent.com/Intika-Linux-Plasmoid/plasmoid-desktop-previous/master/version");
        xhr.onreadystatechange = function() {
            if (xhr.readyState == XMLHttpRequest.DONE) {
                updateResponse = xhr.responseText;
                console.log('.'+updateResponse+'.');
                console.log('.'+currentVersion+'.');
                //console.log('.'+xhr.status+'.');
                //console.log('.'+xhr.statusText+'.');
                if (updateResponse.localeCompare(currentVersion) && updateResponse.localeCompare('') && updateResponse.localeCompare('404: Not Found\n')) {
                    availableUpdate();
                } else if (notifyUpdated) {
                    noAvailableUpdate();
                }
            }
        };
        xhr.send();
    }
    
    function action_checkUpdate() {
        updaterNotification(true);
    }
    // ==============================================================================================================================================

	Component.onCompleted: {
		plasmoid.setAction("showDesktopGrid", i18n("Show Desktop Grid"), "view-grid");
        
        // Updater 3/3 ==============================================================================================================================
        plasmoid.setAction("checkUpdate", i18n("Check for updates on github"), "view-grid");
        if (checkUpdateStartup) {timerStartUpdater.start();}
        // ==========================================================================================================================================
	}
}


