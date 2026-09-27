import Foundation

var cloudKitContainerIdentifier =
    "iCloud.com.rs6apps.TransitICScanner"
var AppGroup = "group.com.rs6apps.TransitICScanner"

func debugStorage(_ isDebug:Bool) {
    if isDebug {
        cloudKitContainerIdentifier =
        "iCloud.com.rs6apps.TransitICScanner.debug"
        AppGroup = "group.com.rs6apps.TransitICScanner.debug"
    } else {
        cloudKitContainerIdentifier =
        "iCloud.com.rs6apps.TransitICScanner"
        AppGroup = "group.com.rs6apps.TransitICScanner"
    }
}
