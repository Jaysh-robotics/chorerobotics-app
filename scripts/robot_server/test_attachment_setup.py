import asyncio
import json
import unittest
import copy
import os
import tempfile
from unittest.mock import patch

from simulated_robot_server import SimulatedRobotServer


class Socket:
    def __init__(self):
        self.messages = []

    async def send(self, message):
        self.messages.append(json.loads(message))


class AttachmentSetupTests(unittest.TestCase):
    def test_defaults_validation_ack_readback_and_restart(self):
        async def scenario():
            with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, {
                "CHOREROBOT_DEFAULTS_PATH": os.path.join(directory, "defaults.json")
            }):
                server = SimulatedRobotServer("127.0.0.1", 0, None)
                socket = Socket()
                defaults = copy.deepcopy(server.state.mower_defaults)
                defaults["pattern"] = "spiral"
                async def send(kind, payload):
                    await server._handle_message(socket, json.dumps({"type": kind, "id": "save", "payload": payload}))
                    return socket.messages[-1]["payload"]
                self.assertEqual((await send("mower_defaults_set", defaults))["status"], "accepted")
                for key, value in (("cut_height_mm", 101), ("pass_overlap_percent", -1),
                                   ("stripe_angle_degrees", True), ("pattern", "invalid")):
                    invalid = {**defaults, key: value}
                    self.assertEqual((await send("mower_defaults_set", invalid))["status"], "rejected")
                invalid = copy.deepcopy(defaults)
                invalid["schedule"]["days"] = []
                self.assertEqual((await send("mower_defaults_set", invalid))["status"], "rejected")
                server = SimulatedRobotServer("127.0.0.1", 0, None)
                result = await send("mower_defaults_get", {})
                self.assertEqual(result["defaults"], defaults)
                self.assertTrue(result["saved"])
                server.state.estop_active = True
                self.assertEqual((await send("mower_defaults_set", defaults))["message"], "estop_active")
        asyncio.run(scenario())

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
