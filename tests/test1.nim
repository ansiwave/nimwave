import unittest

type
  State = object

include nimwave/prelude

from nimwave as nw import nil

test "can initialize prelude":
  discard nw.initContext[State]()
