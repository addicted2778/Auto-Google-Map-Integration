import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ProjectSelector extends StatefulWidget {
  const ProjectSelector({super.key});

  @override
  State<ProjectSelector> createState() => _ProjectSelectorState();
}

class _ProjectSelectorState extends State<ProjectSelector> {
  final apiKeyFormKey = GlobalKey<FormState>();

  void selectProject(BuildContext context) async {
    String? selectedDir = await FilePicker.platform.getDirectoryPath();
    if (selectedDir != null) {
      // Check if pubspec.yaml exists in the selected directory
      final pubspecPath = '$selectedDir/pubspec.yaml';
      if (await File(pubspecPath).exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected project: $selectedDir')),
        );
        addDependency(selectedDir);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid Flutter project directory!')),
        );
      }
    }
  }

  addDependency(String projectDir) async {
    final pubspecPath = '$projectDir/pubspec.yaml';
    final pubspecFile = File(pubspecPath);

    if (await pubspecFile.exists()) {
      final lines = await pubspecFile.readAsLines();
      if (!lines.any((line) => line.contains('google_maps_flutter:'))) {
        // Add dependency
        lines.insert(
            lines.indexWhere((line) => line.startsWith('dependencies:')) + 1,
            '  google_maps_flutter: ^2.10.0');
        await pubspecFile.writeAsString(lines.join('\n'));

        // Run `flutter pub get`
        final result = await Process.run('flutter', ['pub', 'get'],
            workingDirectory: projectDir);
        if (result.exitCode == 0) {
          showDialog(
              context: context, builder: (context) => enterApiKey(projectDir));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('Error running flutter pub get: ${result.stderr}')));
        }
      } else {
        final result = await Process.run('flutter', ['pub', 'get'],
            workingDirectory: projectDir);
        showDialog(
            context: context, builder: (context) => enterApiKey(projectDir));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('pubspec.yaml not found in $projectDir')));
    }
  }

  Widget enterApiKey(String dir) {
    TextEditingController controller = TextEditingController();
    return AlertDialog(
      title: Text('Enter Google Maps API Key'),
      content: Form(
        key: apiKeyFormKey,
        child: TextFormField(
          controller: controller,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "This filed can't be empty";
            } else {
              return null;
            }
          },
          decoration: InputDecoration(hintText: 'Enter your API key'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (apiKeyFormKey.currentState!.validate()) {
              onApiKeyProvided(controller.text, dir);
              Navigator.of(context).pop();
            }
          },
          child: Text('Submit'),
        ),
      ],
    );
  }

  onApiKeyProvided(
    String apikey,
    String projectDir,
  ) {
    configureAndroid(projectDir, apikey);
    configureiOS(projectDir, apikey);
  }

  void configureAndroid(String projectDir, String apiKey) async {
    final manifestPath = '$projectDir/android/app/src/main/AndroidManifest.xml';
    final manifestFile = File(manifestPath);

    if (await manifestFile.exists()) {
      String content = await manifestFile.readAsString();

      if (!content.contains('com.google.android.geo.API_KEY')) {
        content = content.replaceFirst(
          '</application>',
          '''
          <meta-data
                android:name="com.google.android.geo.API_KEY"
                android:value="$apiKey" />
        </application>
            
        ''',
        );
        await manifestFile.writeAsString(content);
        print('AndroidManifest.xml updated with API key.');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AndroidManifest.xml not found!')));
    }
  }


  void configureiOS(String projectDir, String apiKey) async {
    final plistPath = '$projectDir/ios/Runner/Info.plist';
    final plistFile = File(plistPath);
    final delegatePath = '$projectDir/ios/Runner/AppDelegate.swift';
    final delegateFile = File(delegatePath);
    final podpath = '$projectDir/ios/Podfile';
    final podfile = File(podpath);
    final mainpath = '$projectDir/lib/main.dart';
    final mainFile = File(mainpath);

    if (await plistFile.exists()) {
      String content = await plistFile.readAsString();

      if (!content.contains('<key>GMSApiKey</key>')) {
        content = content.replaceFirst(
          '</dict>',
          '''
        <key>GMSApiKey</key>
        <string>$apiKey</string>
        </dict>
        ''',
        );
        await plistFile.writeAsString(content);
        print('Info.plist updated with API key.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'An Another Google Map API Key already exists, please update manually in $plistPath')));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Info.plist not found!')));
    }

    if (await delegateFile.exists()) {
      String delegateContent = await delegateFile.readAsString();

      if (!delegateContent.contains('GMSServices.provideAPIKey("$apiKey")')) {
        delegateContent = "import GoogleMaps\n" + delegateContent;

        delegateContent = delegateContent.replaceFirst(
            'GeneratedPluginRegistrant.register(with: self)',
            '''  GMSServices.provideAPIKey("$apiKey")
          GeneratedPluginRegistrant.register(with: self)
        ''');
        await delegateFile.writeAsString(delegateContent);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Congratulations, you have successfully added google map to your project')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AppDelegate.swift file not found!')));
    }

    if (await podfile.exists()) {
      String podContent = await podfile.readAsString();

      podContent =
          "# Uncomment this line to define a global platform for your project\nplatform :ios, '14.0'" +
              podContent;

      await podfile.writeAsString(podContent);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Podfile not found!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Flutter Project')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => selectProject(context),
          child: Text('Select Project'),
        ),
      ),
    );
  }
}
