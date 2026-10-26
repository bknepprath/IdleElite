from pathlib import Path
from PIL import Image
import numpy as np
from scipy import ndimage
import json
root=Path(__file__).resolve().parents[2]/'outputs/verification/production-window-rounding-oct25/final'
results=[]
count=json.loads((root/'result.json').read_text())['corner_pngs']
for frame in range(count):
 path=root/f'corner-frame-{frame:03d}.png'
 im=Image.open(path).convert('RGB')
 assert im.size==(1080,1920)
 a=np.array(im,dtype=np.int16)[630:825,65:1015]
 r,g,b=a[:,:,0],a[:,:,1],a[:,:,2]
 mask=(r>180)&(g>150)&(b<120)&(g-b>90)&(r-g<60)
 labels,count=ndimage.label(mask,np.ones((3,3)))
 sizes=np.bincount(labels.ravel()); sizes[0]=0
 main=labels==int(sizes.argmax())
 holes=ndimage.binary_fill_holes(main)&~main
 hlabels,hcount=ndimage.label(holes)
 hsizes=np.bincount(hlabels.ravel())[1:]
 large_holes=int((hsizes>50).sum())
 extra=int((sizes>100).sum())-1
 results.append({'file':path.name,'stroke_pixels':int(main.sum()),'large_holes':large_holes,'extra_parts':extra,'passed':main.sum()>400 and large_holes==1 and extra==0})
failures=[x for x in results if not x['passed']]
(root/'pixel-audit.json').write_text(json.dumps({'frames':results,'failures':failures},indent=2))
print('PIXEL_AUDIT frames=',len(results),'closed continuous rings=',sum(x['passed'] for x in results),'failures=',failures[:8])
assert not failures
