from PIL import Image
from pathlib import Path
root=Path('.'); stage=root/'tmp/imagegen/dragon-states-s09a'; out=root/'assets/content/fight/enemies/dragons'
def bbox(im): return im.getchannel('A').getbbox()
def place(src, name, width=404):
    im=Image.open(src).convert('RGBA'); b=bbox(im)
    crop=im.crop(b); crop=crop.resize((width, round(crop.height*width/crop.width)), Image.Resampling.LANCZOS)
    cell=Image.new('RGBA',(512,512),(0,0,0,0)); x=256-width//2; y=448-crop.height
    cell.alpha_composite(crop,(x,y)); cell.save(out/name)
master=Image.open(root/'tmp/imagegen/diamond-fight-base-models/approved-sources/dragon-base-approved-master.png').convert('RGBA')
b=bbox(master); crop=master.crop(b); crop=crop.resize((404, round(crop.height*404/crop.width)), Image.Resampling.LANCZOS)
cell=Image.new('RGBA',(512,512),(0,0,0,0)); cell.alpha_composite(crop,(54,448-crop.height)); cell.save(out/'dragons-idle.png')
place(stage/'hit-alpha.png','dragons-hit.png'); place(stage/'dizzy-alpha.png','dragons-dizzy.png'); place(stage/'defeated-alpha.png','dragons-defeated.png')
strip=Image.new('RGBA',(2048,512),(0,0,0,0))
for i,n in enumerate(['dragons-idle.png','dragons-hit.png','dragons-dizzy.png','dragons-defeated.png']): strip.alpha_composite(Image.open(out/n).convert('RGBA'),(512*i,0))
strip.save(out/'dragons-states-source.png')
