import 'package:chorerobotics/core/app/robot_app_controller.dart';
import 'package:chorerobotics/core/robot/robot_command_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mower flow remains usable without a server connection', () {
    final client = RobotCommandClient();
    final app = RobotAppController(client);
    addTearDown(() {
      app.dispose();
      client.dispose();
    });

    app.setStripePattern('checker');
    app.setCutHeight(65);
    app.setZone('zone_3', 'Zone 3');
    app.saveSchedule(
      const MowerSchedule(hour: 7, minute: 30, period: 'AM', days: {1, 3, 5}),
    );

    expect(app.stripePattern, 'checker');
    expect(app.cutHeightMm, 65);
    expect(app.zoneName, 'Zone 3');
    expect(app.schedule?.formattedTime, '07:30 AM');

    app.startMowing();
    expect(app.taskStatus, RobotTaskStatus.running);

    app.pauseTask();
    expect(app.taskStatus, RobotTaskStatus.paused);

    app.resumeTask();
    expect(app.taskStatus, RobotTaskStatus.running);

    app.emergencyStop();
    expect(app.taskStatus, RobotTaskStatus.cancelled);
  });
}
