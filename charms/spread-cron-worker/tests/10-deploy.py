#!/usr/bin/python3

import amulet
import unittest

class TestCharm(unittest.TestCase):
    def setUp(self):
        self.d = amulet.Deployment()

        self.d.add('spread-cron')

        self.d.setup(timeout=900)
        self.d.sentry.wait()

        self.unit = self.d.sentry['spread-cron'][0]

    def test_service_up(self):
        spread_cron = self.d.sentry['spread-cron'][0]
        output, exit_code = spread_cron.run('systemctl status snap.spread-cron.cron.service')
        self.assertTrue(exit_code == 0)

        # check for cron actually working, credentials should not be set by now
        expected = "No credentials file found"
        self.assertTrue(expected in output)
