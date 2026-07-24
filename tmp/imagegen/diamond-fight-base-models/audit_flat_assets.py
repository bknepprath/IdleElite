from pathlib import Path
import sys

import numpy as np
from PIL import Image


for path in sorted(Path(sys.argv[1]).glob("*-base.png")):
    pixels = np.asarray(Image.open(path).convert("RGBA"))
    visible = pixels[:, :, 3] > 0
    ys, xs = np.nonzero(visible)
    colors = len(np.unique(pixels[:, :, :3][pixels[:, :, 3] == 255], axis=0))
    alphas = set(np.unique(pixels[:, :, 3]).tolist())
    padding = (
        int(xs.min()),
        int(pixels.shape[1] - 1 - xs.max()),
        int(ys.min()),
        int(pixels.shape[0] - 1 - ys.max()),
    )
    assert pixels.shape == (640, 640, 4)
    assert colors <= 32
    assert alphas <= {0, 255}
    assert min(padding) >= 100
    print(f"{path.name}: colors={colors}, alpha={sorted(alphas)}, padding={padding}")
