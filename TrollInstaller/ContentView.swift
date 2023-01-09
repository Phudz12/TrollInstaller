//
//  ContentView.swift
//  TrollInstaller
//
//  Created by Hornbeck on 1/9/23.
//

import SwiftUI
import SWCompression
import Light_Swift_Untar

struct ContentView: View {
    @State var Log = ""
    @State var InstalledTrollStore = false
    @State var Installldid = true
    @State var InstallPersistenceHelper = true
    var body: some View {
        NavigationView {
            Form {
                if !Log.isEmpty {
                    Section {
                        Text(Log)
                    }
                }
                Section(header: Text("Be Patient, This Takes A Few Years")) {
                    Button {
                        cicuta_virosa()
                    } label: {
                        Text("Exploit")
                    }
                }
                Section(footer: Text("Created By Benjamin Hornbeck (@AppInstalleriOS)")) {
                    Button {
                        OpenApp("com.opa334.TrollStore")
                    } label: {
                        Text("Open TrollStore")
                    }
                    .disabled(!InstalledTrollStore)
                    Button {
                        DispatchQueue.global(qos: .utility).async {
                            InstallTrollStore(Log: $Log, Installldid: Installldid, InstallPersistenceHelper: InstallPersistenceHelper)
                            InstalledTrollStore = true
                        }
                    } label: {
                        Text("Install TrollStore")
                    }
                    Toggle("Install ldid", isOn: $Installldid)
                    Toggle("Install Persistence Helper", isOn: $InstallPersistenceHelper)
                }
            }
            .navigationTitle("TrollInstaller")
        }
    }
}

func InstallTrollStore(Log: Binding<String>, Installldid: Bool, InstallPersistenceHelper: Bool) {
    do {
        Log.wrappedValue = "Remounting /private/preboot"
        runBinary("/sbin/mount", ["-u", "-w", "/private/preboot"], nil)
        let tmpDir = "/private/preboot/tmp"
        if FileManager.default.fileExists(atPath: tmpDir) {
            try FileManager.default.removeItem(atPath: tmpDir)
        }
        try FileManager.default.createDirectory(atPath: tmpDir, withIntermediateDirectories: false)
        Log.wrappedValue = "Downloading TrollStore.tar"
        FileManager.default.createFile(atPath: "\(tmpDir)/TrollStore.tar", contents: try Data(contentsOf: URL(string: "https://github.com/opa334/TrollStore/releases/latest/download/TrollStore.tar")!))
        Log.wrappedValue = "Extracting TrollStore.tar"
        try GzipArchive.unarchive(archive: FileManager.default.contents(atPath: "\(tmpDir)/TrollStore.tar") ?? Data()).write(to: URL(fileURLWithPath: "\(tmpDir)/TrollStore-Tmp.tar"))
        try FileManager.default.createFilesAndDirectories(path: "\(tmpDir)/TrollStore", tarPath: "\(tmpDir)/TrollStore-Tmp.tar")
        try FileManager.default.moveItem(atPath: "\(tmpDir)/TrollStore/TrollStore.app", toPath: "\(tmpDir)/TrollStore.app")
        let tsTarPath = "\(tmpDir)/TrollStore.tar"
        let helperPath = "\(tmpDir)/TrollStore.app/trollstorehelper"
        chmod(helperPath, 0755)
        chown(helperPath, 0, 0)
        Log.wrappedValue = "Installing TrollStore"
        runBinary(helperPath, ["install-trollstore", tsTarPath], nil)
        Log.wrappedValue = "Installed TrollStore"
        if Installldid {
            Log.wrappedValue = "Installing ldid"
            FileManager.default.createFile(atPath: "\(tmpDir)/ldid", contents: try Data(contentsOf: URL(string: "https://github.com/opa334/ldid/releases/download/v2.1.5-procursus5/ldid")!))
            runBinary(helperPath, ["install-ldid", "\(tmpDir)/ldid"], nil)
            Log.wrappedValue = "Installed ldid"
        }
        if InstallPersistenceHelper {
            Log.wrappedValue = "Installing Persistence Helper"
            runBinary(helperPath, ["install-persistence-helper", "com.apple.tips"], nil)
            Log.wrappedValue = "Installed Persistence Helper"
        }
        if FileManager.default.fileExists(atPath: tmpDir) {
            try FileManager.default.removeItem(atPath: tmpDir)
        }
    } catch {
        Log.wrappedValue = error.localizedDescription
    }
}

func OpenApp(_ BundleId: String) {
    guard let obj = objc_getClass("LSApplicationWorkspace") as? NSObject else { return }
    let workspace = obj.perform(Selector(("defaultWorkspace")))?.takeUnretainedValue() as? NSObject
    workspace?.perform(Selector(("openApplicationWithBundleID:")), with: BundleId)
}
