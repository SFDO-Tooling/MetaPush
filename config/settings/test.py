from .base import *  # NOQA

CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "MetaPush.tests.layer_utils.MockedRedisInMemoryChannelLayer"
    }
}
