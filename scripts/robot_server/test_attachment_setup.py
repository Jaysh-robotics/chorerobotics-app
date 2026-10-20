import asyncio
import json
import unittest

from simulated_robot_server import SimulatedRobotServer


class Socket:
    def __init__(self):
        self.messages = []

    async def send(self, message):
        self.messages.append(json.loads(message))


class AttachmentSetupTests(unittest.TestCase):
    def test_select_detect_and_reject_unknown_attachment(self):
        async def scenario():
            server = SimulatedRobotServer("127.0.0.1", 0, None)
            socket = Socket()
            for attachment in ("mower", "trimmer", "irrigator", "collector", "blower", "plow", "patrol"):
                await server._handle_message(socket, json.dumps({"type": "attachment_select", "id": "select", "payload": {"attachment": attachment}}))
                self.assertEqual(socket.messages[-1]["payload"]["status"], "accepted")
                await server._handle_message(socket, json.dumps({"type": "attachment_detect", "id": "detect"}))
                self.assertEqual(socket.messages[-1]["payload"]["attachment"], attachment)
            await server._handle_message(socket, json.dumps({"type": "attachment_select", "id": "bad", "payload": {"attachment": "unknown"}}))
            self.assertEqual(socket.messages[-1]["payload"]["status"], "rejected")
            self.assertEqual(server.state.selected_attachment, "patrol")

        asyncio.run(scenario())


if __name__ == "__main__":
    unittest.main()
