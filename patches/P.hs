module P where

import Control.Monad

import Csound.Base 

import qualified Flavio as C
import qualified Thor   as C
import qualified Thor   as T
import qualified Csound.Catalog.Wave as C
import qualified Csound.Catalog.Reson as C
import qualified Patch as C
import qualified Sean as C

import Data.Char

type CsdNote = (D, D)

type Instr a = CsdNote -> SE a
type Fx a = a  -> SE a

type Patch1 = Patch Sig
type Patch2 = Patch Sig2

data Patch a = Patch
	{ patchInstr :: Instr a
	, patchFx	 :: Fx a
	, patchMix   :: Sig	
	}

wet :: (SigSpace a, Sigs a) => Sig -> Fx a -> a -> SE a
wet k fx asig = fmap ((mul (1 - k) asig + ) . mul k) $ fx asig

dryMidi :: (Sigs a) => Patch a -> SE a
dryMidi a = midi (patchInstr a . ampCps)

atMidi' :: (SigSpace a, Sigs a) => Sig -> Patch a -> SE a
atMidi' k a = wet k (patchFx a) =<< midi (patchInstr a . ampCps)	

atMidi :: (SigSpace a, Sigs a) => Patch a -> SE a
atMidi a = atMidi' (patchMix a) a

----------------------------------------------
-- electric pianos

data Epiano1 = Epiano1 
	{ epiano1Rel :: D }

instance Default Epiano1 where
	def = Epiano1 5	

epiano1 = epiano1' def

epiano1' (Epiano1 rel) = Patch 
	{ patchInstr = \a -> mul 0.45 $ C.simpleFading rel a
	, patchFx    = return . largeHall2
	, patchMix    = 0.25
	}

data MutedPiano = MutedPiano 
	{ mutedPianoMute :: Sig
	, mutedPianoRel  :: D
	}

instance Default MutedPiano where
	def = MutedPiano 0.5 7

mutedPiano = mutedPiano' def

mutedPiano' (MutedPiano mute rel) = Patch 
	{ patchInstr = \a -> mul 0.8 $ C.simpleSust rel a
	, patchFx    = return . largeHall2 . at (mlp3 (250 + 7000 * mute) 0.2)
	, patchMix    = 0.25
	}

amPiano = Patch
	{ patchInstr = mul 2 . onCps C.amPiano
	, patchFx    = return
	, patchMix    = 0.25
	}

fmPiano = Patch
	{  patchInstr = at fromMono . onCps (C.fm 6 3)
	, patchFx     = return . smallHall2
	, patchMix    = 0.15
	}

epiano2 = Patch 
	{ patchInstr = mul 1.5 . at fromMono . (onCps $ C.epiano [C.EpianoOsc 4 5 1 1, C.EpianoOsc 8 10 2.01 1])
	, patchFx    = return . smallHall2
	, patchMix    = 0.25
	}

epianoHeavy = Patch 
	{ patchInstr = mul 1.5 . at fromMono . (onCps $ C.epiano [C.EpianoOsc 4 5 1 1, C.EpianoOsc 8 10 2.01 1, C.EpianoOsc 8 15 0.5 0.5])
	, patchFx    = return . smallHall2
	, patchMix    = 0.2
	}

epianoBright = Patch 
	{ patchInstr = mul 1.5 . at fromMono . (onCps $ C.epiano [C.EpianoOsc 4 5 1 1, C.EpianoOsc 8 10 3.01 1, C.EpianoOsc 8 15 5 0.5, C.EpianoOsc 8 4 7 0.3])
	, patchFx    = return . smallHall2
	, patchMix    = 0.2
	}

vibraphonePiano1 = smallVibraphone1 { patchInstr = mul (1.5 * fadeOut 0.25) . at (mlp 6500 0.1). patchInstr smallVibraphone1 }
vibraphonePiano2 = smallVibraphone2 { patchInstr = mul (1.5 * fadeOut 0.25) . at (mlp 6500 0.1). patchInstr smallVibraphone2 }

----------------------------------------------
-- organs

cathedralOrgan = Patch
	{ patchInstr = at fromMono . mul 1.2 . onCps C.cathedralOrgan
	, patchFx    = return . largeHall2
	, patchMix   = 0.27
	}

-- [0, 30]
data HammondOrgan = HammondOrgan 
	{ hammondOrganDetune :: Sig }

instance Default HammondOrgan where
	def = HammondOrgan 12

hammondOrgan = hammondOrgan' def

hammondOrgan' (HammondOrgan detune) = Patch
	{ patchInstr = mul 0.8 . at fromMono . onCps (C.hammondOrgan detune)
	, patchFx    = return . smallRoom2
	, patchMix   = 0.15
	}

toneWheel = Patch
	{ patchInstr = at fromMono  . mul 1.2 . onCps C.toneWheel
	, patchFx    = return . smallHall2
	, patchMix   = 0.3
	}

sawOrgan = waveOrgan rndSaw
triOrgan = waveOrgan rndTri
sqrOrgan = waveOrgan rndSqr
pwOrgan k = waveOrgan (rndPw k)

waveOrgan :: (Sig -> SE Sig) -> Patch2 
waveOrgan wave = Patch 
	{ patchInstr = onCps $ at fromMono . mul (fades 0.01 0.01) . at (mlp 3500 0.1) . wave
	, patchFx    = return . smallHall2
	, patchMix   = 0.25
	}

----------------------------------------------
-- accordeons

accordeon = accordeon' def

accordeonBright = accordeon' (C.Accordeon 1 5 3 7)
accordeonBright2 = accordeon' (C.Accordeon 1 6 3 13)

accordeonHeavy = accordeon' (C.Accordeon 1 0.501 2 1.005)
brokenAccordeon = accordeon' (C.Accordeon 1 1.07 2.02 0.5)

accordeon' spec = Patch
	{ patchInstr = mul 1.2 . onCps (C.accordeon spec)
	, patchFx    = C.accordeonFx
	, patchMix   = 0.25
	}

----------------------------------------------
-- choir

data Choir = Choir { choirVibr :: Sig }

instance Default Choir where
	def  = Choir 7

tenor' filt (Choir vib) = Patch 
	{ patchInstr = at fromMono . mul 0.3 . onCps (C.tenorOsc filt vib)
	, patchFx    = return . smallHall2
	, patchMix   = 0.25
	}

soprano' filt (Choir vib) = Patch 
	{ patchInstr = at fromMono . mul 0.3 . onCps (C.sopranoOsc filt vib)
	, patchFx    = return . smallHall2
	, patchMix   = 0.25
	}

choir' filt vib = Patch
	{ patchInstr = \(amp, cps) -> do
			ref <- newSERef (0 :: Sig2)
			when1 (sig cps <=* 220) $ writeSERef ref =<< (patchInstr (tenor'   filt vib) (amp, cps))
			when1 (sig cps >*  220) $ writeSERef ref =<< (patchInstr (soprano' filt vib) (amp, cps))
			readSERef ref
	, patchFx   = return . smallHall2 
	, patchMix   = 0.25 
	}

choirA = choirA' def
choirO = choirO' def
choirE = choirE' def
choirU = choirU' def

choirA' = choir' singA
choirO' = choir' singO
choirE' = choir' singE
choirU' = choir' singU

data NoisyChoir = NoisyChoir 
	{ noisyChoirFilterNum :: Int
	, noisyChoirBw        :: Sig
	}

instance Default NoisyChoir where
	def = NoisyChoir 2 25

windSings = longNoisyChoir' (NoisyChoir 1 15)

longNoisyChoir = longNoisyChoir' def
noisyChoir = noisyChoir' def


longNoisyChoir' (NoisyChoir n bw) = Patch
	{ patchInstr = at fromMono . onCps (C.noisyChoir n bw)
	, patchFx    = return . magicCave2
	, patchMix   = 0.15
	}

noisyChoir' ch = (longNoisyChoir' ch) { patchFx    = return . largeHall2 }

-- modes (wth delay or not delay)
--
--  dac $ mixAt 0.15 largeHall2 $ mixAt 0.2 (echo 0.25 0.45) $ at fromMono $ midi $ onMsg $ onCps (mul (fadeOut 2) . C.tibetanBowl152    )

----------------------------------------------
-- pads

pwPad = Patch
	{ patchInstr = mul 1.2 . at fromMono . onCps C.pwPad
	, patchFx    = return . smallHall2
	, patchMix   = 0.25
	}

nightPad = Patch
	{ patchInstr = mul 0.8 . at fromMono . onCps (mul (fadeOut 1) . C.nightPad 0.5)
	, patchFx    = return . largeHall2
	, patchMix   = 0.25
	}

overtonePad = Patch
	{ patchInstr = mul 1.2 . at fromMono . mixAt 0.25 (mlp 1500 0.1) . onCps (\cps -> mul (fades 0.25 1.2) (C.tibetan 11 0.012 cps) + mul (fades 0.25 1) (C.tibetan 13 0.015 (cps * 0.5)))
	, patchFx    = return . smallHall2
	, patchMix   = 0.35
	}

caveOvertonePad = overtonePad { patchFx    = return . magicCave2 . mul 0.8, patchMix   = 0.2 }

chorusel = Patch
	{ patchInstr = mul 1.2 . at (mlp (3500 + 2000 * uosc 0.1) 0.1) . onCps (mul (fades 0.65 1) . C.chorusel 13 0.5 10)
	, patchFx    = return . smallHall2
	, patchMix   = 0.35
	}

pwEnsemble = Patch
	{ patchInstr = at fromMono . onCps C.pwEnsemble
	, patchFx    = return . smallHall2
	, patchMix   = 0.25
	}

fmDroneSlow = Patch
	{ patchInstr = at fromMono . onCps (C.fmDrone 3 (10, 5))
	, patchFx    = return . largeHall2
	, patchMix   = 0.35
	}

fmDroneMedium = Patch
	{ patchInstr = at fromMono . onCps (C.fmDrone 3 (5, 3))
	, patchFx    = return . smallHall2
	, patchMix   = 0.25
	}

fmDroneFast = Patch
	{ patchInstr = at fromMono . onCps (C.fmDrone 3 (0.5, 1))
	, patchFx    = return . smallHall2
	, patchMix   = 0.25
	}
 

vibrophonePad = largeVibraphone1 { patchInstr = mul (2 * fades 0.5 0.25) . at (mlp 2500 0.1). patchInstr largeVibraphone1 }

data RazorPad = RazorPad { razorPadSpeed :: Sig }

instance Default RazorPad where
	def = RazorPad 0.5

razorPadSlow = razorPad' (def { razorPadSpeed = 0.1 })
razorPadFast = razorPad' (def { razorPadSpeed = 1.7 })
razorPadTremolo = razorPad' (def { razorPadSpeed = 6.7 })

razorPad = razorPad' def

razorPad' (RazorPad speed) = Patch
	{ patchInstr = at fromMono . onCps (uncurry $ C.razorPad speed)
	, patchFx    = return . largeHall2
	, patchMix   = 0.35
	}

------------------------------------
-- leads

phasingLead = Patch
	{ patchInstr = at fromMono . mul (fadeOut 0.05) . onCps (uncurry C.phasingSynth)
	, patchFx    = return . smallHall2
	, patchMix   = 0.25
	}

data RazorLead = RazorLead 
	{ razorLeadBright :: Sig 
	, razorLeadSpeed  :: Sig }

instance Default RazorLead where
	def = RazorLead 0.5 0.5

razorLeadSlow = razorLead' (def { razorLeadSpeed = 0.1 })
razorLeadFast = razorLead' (def { razorLeadSpeed = 1.7 })
razorLeadTremolo = razorLead' (def { razorLeadSpeed = 6.7 })

razorLead = razorLead' def

razorLead' (RazorLead bright speed) = Patch
	{ patchInstr = at fromMono . (\(amp, cps) -> mul (fadeOut (0.05 + amp * 0.3)) $ C.razorLead (bright * sig amp) (speed * sig amp) (sig amp) (sig cps))
	, patchFx    = return . smallHall2
	, patchMix   = 0.35
	}

overtoneLeadFx :: Sig2 -> SE Sig2
overtoneLeadFx x = fmap magicCave2 $ mixAt 0.2 (echo 0.25 0.45) (return x)

overtoneLead :: Patch2
overtoneLead = Patch
	{ patchInstr = mul 0.8 . at fromMono . onCps (mul (fades 0.01 1) . C.tibetan 13 0.012)
	, patchFx    = overtoneLeadFx
	, patchMix   = 0.15
	}

------------------------------------
-- bass

simpleBass = Patch 
	{ patchInstr = at fromMono . onCps C.simpleBass
	, patchFx    = return . smallRoom2
	, patchMix   = 0.25
	}

pwBass = Patch 
	{ patchInstr = at fromMono . onCps C.pwBass
	, patchFx    = return . smallHall2
	, patchMix   = 0.25
	}

------------------------------------
-- plucked

guitar = Patch
	{ patchInstr = onCps $ fromMono . mul (fades 0.01 0.25) . C.plainString
	, patchFx    = return . smallHall2
	, patchMix   = 0.25
	}

harpsichord = Patch
	{ patchInstr = onCps $ fromMono . mul (fades 0.01 0.13) . C.harpsichord
	, patchFx    = return . smallHall2
	, patchMix   = 0.25
	}

-- guita

------------------------------------
-- strike

strikeFx :: Strike -> Sig2 -> SE Sig2
strikeFx spec a = at (strikeReverb spec) $ (if (strikeHasDelay spec) then (mixAt 0.35 (echo 0.25 0.55)) else id) (return a :: SE Sig2)

strikeRelease :: (D, D) -> Strike -> D
strikeRelease (amp, cps) spec = (0.85 * strikeRel spec * amp) * amp + (strikeRel spec) - (cps / 10000)

-- dac $ mixAt 0.15 largeHall2 $ mixAt 0.2 (echo 0.25 0.45) $ at fromMono $ midi $ onMsg $ onCps (mul (fadeOut 2) . C.tibetanBowl152 )
data Strike = Strike 
	{ strikeRel :: D
	, strikeHasDelay ::	Bool
	, strikeReverb :: Sig2 -> Sig2		
	}

instance Default Strike where
	def = Strike 1.5 True smallHall2

strike' :: Strike -> (Sig -> Sig) -> Patch Sig2
strike' spec instr = Patch 
	{ patchInstr =  \x@(amp, cps) -> return $ fromMono $ mul (sig amp * fadeOut (rel x)) $ instr (sig cps)
	, patchFx    = strikeFx spec
	, patchMix   = 0.25
	}
	where rel a = strikeRelease a spec


data Size = Small | Medium | Large | Huge

nextSize x = case x of
	Small -> Medium
	Medium -> Large
	Large -> Huge
	Huge -> Huge

prevSize x = case x of
	Small -> Small
	Medium -> Small
	Large -> Medium
	Huge -> Large

toStrikeSpec :: Size -> Size -> Strike
toStrikeSpec revSpec restSpec = Strike 
	{ strikeReverb  = toReverb revSpec
	, strikeRel = toRel restSpec
	, strikeHasDelay = toHasDelay restSpec } 

toReverb :: Size -> (Sig2  -> Sig2)
toReverb x = case x of
	Small -> smallRoom2
	Medium -> smallHall2
	Large -> largeHall2
	Huge -> magicCave2

toRel :: Size -> D
toRel x = case x of
	Small -> 0.4
	Medium -> 1.5
	Large -> 2.5
	Huge -> 4.5

toGain :: Size -> Sig
toGain x = case x of
	Small -> 0.85
	Medium -> 0.75
	Large -> 0.6
	Huge -> 0.45

toHasDelay :: Size -> Bool
toHasDelay x = case x of
	Small -> False
	_     -> True

dahinaSize    		= Small
banyanSize    		= Medium
xylophoneSize 		= Small
tibetanBowl152Size  	= Medium
tibetanBowl140Size  	= Small
tibetanBowl180Size  	= Medium
spinelSphereSize    	= Small
potLidSize          	= Medium
redCedarWoodPlateSize = Small
tubularBellSize     	= Large
redwoodPlateSize    	= Small
douglasFirWoodPlateSize = Small
uniformWoodenBarSize = Small
uniformAluminumBarSize = Small
vibraphone1Size = Medium
vibraphone2Size = Medium
chalandiPlatesSize = Medium
wineGlassSize  = Medium
smallHandbellSize = Medium
albertClockBellBelfastSize = Large
woodBlockSize = Small

smallStrike :: Size -> (Sig -> Sig) -> Patch2
smallStrike size = mediumStrike' (prevSize size) size

mediumStrike :: Size -> (Sig -> Sig) -> Patch2
mediumStrike size = mediumStrike' size size

largeStrike :: Size -> (Sig -> Sig) -> Patch2
largeStrike size = mediumStrike' (nextSize size) size

magicStrike :: Size -> (Sig -> Sig) -> Patch2
magicStrike size = mediumStrike' (nextSize $ nextSize size) size

mediumStrike' :: Size -> Size -> (Sig -> Sig) -> Patch2
mediumStrike' revSize size f = p { patchInstr = mul (toGain size) . patchInstr p }
	where p = strike' (toStrikeSpec revSize size) f


smallDahina = smallStrike dahinaSize C.dahina
dahina = mediumStrike dahinaSize C.dahina
largeDahina = largeStrike dahinaSize C.dahina
magicDahina = magicStrike dahinaSize C.dahina

smallBanyan = smallStrike banyanSize C.banyan
banyan = mediumStrike banyanSize C.banyan
largeBanyan = largeStrike banyanSize C.banyan
magicBanyan = magicStrike banyanSize C.banyan

smallXylophone = smallStrike xylophoneSize C.xylophone
xylophone = mediumStrike xylophoneSize C.xylophone
largeXylophone = largeStrike xylophoneSize C.xylophone
magicXylophone = magicStrike xylophoneSize C.xylophone

smallTibetanBowl180 = smallStrike tibetanBowl180Size C.tibetanBowl180
tibetanBowl180 = mediumStrike tibetanBowl180Size C.tibetanBowl180
largeTibetanBowl180 = largeStrike tibetanBowl180Size C.tibetanBowl180
magicTibetanBowl180 = magicStrike tibetanBowl180Size C.tibetanBowl180

smallSpinelSphere = smallStrike spinelSphereSize C.spinelSphere
spinelSphere = mediumStrike spinelSphereSize C.spinelSphere
largeSpinelSphere = largeStrike spinelSphereSize C.spinelSphere
magicSpinelSphere = magicStrike spinelSphereSize C.spinelSphere

smallPotLid = smallStrike potLidSize C.potLid
potLid = mediumStrike potLidSize C.potLid
largePotLid = largeStrike potLidSize C.potLid
magicPotLid = magicStrike potLidSize C.potLid

smallRedCedarWoodPlate = smallStrike redCedarWoodPlateSize C.redCedarWoodPlate
redCedarWoodPlate = mediumStrike redCedarWoodPlateSize C.redCedarWoodPlate
largeRedCedarWoodPlate = largeStrike redCedarWoodPlateSize C.redCedarWoodPlate
magicRedCedarWoodPlate = magicStrike redCedarWoodPlateSize C.redCedarWoodPlate

smallTubularBell = smallStrike tubularBellSize C.tubularBell
tubularBell = mediumStrike tubularBellSize C.tubularBell
largeTubularBell = largeStrike tubularBellSize C.tubularBell
magicTubularBell = magicStrike tubularBellSize C.tubularBell

smallRedwoodPlate = smallStrike redwoodPlateSize C.redwoodPlate
redwoodPlate = mediumStrike redwoodPlateSize C.redwoodPlate
largeRedwoodPlate = largeStrike redwoodPlateSize C.redwoodPlate
magicRedwoodPlate = magicStrike redwoodPlateSize C.redwoodPlate

smallDouglasFirWoodPlate = smallStrike douglasFirWoodPlateSize C.douglasFirWoodPlate
douglasFirWoodPlate = mediumStrike douglasFirWoodPlateSize C.douglasFirWoodPlate
largeDouglasFirWoodPlate = largeStrike douglasFirWoodPlateSize C.douglasFirWoodPlate
magicDouglasFirWoodPlate = magicStrike douglasFirWoodPlateSize C.douglasFirWoodPlate

smallUniformWoodenBar = smallStrike uniformWoodenBarSize C.uniformWoodenBar
uniformWoodenBar = mediumStrike uniformWoodenBarSize C.uniformWoodenBar
largeUniformWoodenBar = largeStrike uniformWoodenBarSize C.uniformWoodenBar
magicUniformWoodenBar = magicStrike uniformWoodenBarSize C.uniformWoodenBar

smallUniformAluminumBar = smallStrike uniformAluminumBarSize C.uniformAluminumBar
uniformAluminumBar = mediumStrike uniformAluminumBarSize C.uniformAluminumBar
largeUniformAluminumBar = largeStrike uniformAluminumBarSize C.uniformAluminumBar
magicUniformAluminumBar = magicStrike uniformAluminumBarSize C.uniformAluminumBar

smallVibraphone1 = smallStrike vibraphone1Size C.vibraphone1
vibraphone1 = mediumStrike vibraphone1Size C.vibraphone1
largeVibraphone1 = largeStrike vibraphone1Size C.vibraphone1
magicVibraphone1 = magicStrike vibraphone1Size C.vibraphone1

smallVibraphone2 = smallStrike vibraphone2Size C.vibraphone2
vibraphone2 = mediumStrike vibraphone2Size C.vibraphone2
largeVibraphone2 = largeStrike vibraphone2Size C.vibraphone2
magicVibraphone2 = magicStrike vibraphone2Size C.vibraphone2

smallChalandiPlates = smallStrike chalandiPlatesSize C.chalandiPlates
chalandiPlates = mediumStrike chalandiPlatesSize C.chalandiPlates
largeChalandiPlates = largeStrike chalandiPlatesSize C.chalandiPlates
magicChalandiPlates = magicStrike chalandiPlatesSize C.chalandiPlates

smallTibetanBowl152 = smallStrike tibetanBowl152Size C.tibetanBowl152
tibetanBowl152 = mediumStrike tibetanBowl152Size C.tibetanBowl152
largeTibetanBowl152 = largeStrike tibetanBowl152Size C.tibetanBowl152
magicTibetanBowl152 = magicStrike tibetanBowl152Size C.tibetanBowl152

smallTibetanBowl140 = smallStrike tibetanBowl140Size C.tibetanBowl140
tibetanBowl140 = mediumStrike tibetanBowl140Size C.tibetanBowl140
largeTibetanBowl140 = largeStrike tibetanBowl140Size C.tibetanBowl140
magicTibetanBowl140 = magicStrike tibetanBowl140Size C.tibetanBowl140

smallWineGlass = smallStrike wineGlassSize C.wineGlass
wineGlass = mediumStrike wineGlassSize C.wineGlass
largeWineGlass = largeStrike wineGlassSize C.wineGlass
magicWineGlass = magicStrike wineGlassSize C.wineGlass

smallHandbell = smallStrike smallHandbellSize C.smallHandbell
handbell = mediumStrike smallHandbellSize C.smallHandbell
largeHandbell = largeStrike smallHandbellSize C.smallHandbell
magicHandbell = magicStrike smallHandbellSize C.smallHandbell

smallAlbertClockBellBelfast = smallStrike albertClockBellBelfastSize C.albertClockBellBelfast
albertClockBellBelfast = mediumStrike albertClockBellBelfastSize C.albertClockBellBelfast
largeAlbertClockBellBelfast = largeStrike albertClockBellBelfastSize C.albertClockBellBelfast
magicAlbertClockBellBelfast = magicStrike albertClockBellBelfastSize C.albertClockBellBelfast

smallWoodBlock = smallStrike woodBlockSize C.woodBlock
woodBlock = mediumStrike woodBlockSize C.woodBlock
largeWoodBlock = largeStrike woodBlockSize C.woodBlock
magicWoodBlock = magicStrike woodBlockSize C.woodBlock

---------------------------------------------------------------
-- scrape

-- scrapePatch 

names = ["dahina","banyan","xylophone","tibetanBowl180","spinelSphere","potLid","redCedarWoodPlate","tubularBell","redwoodPlate","douglasFirWoodPlate","uniformWoodenBar","uniformAluminumBar","vibraphone1","vibraphone2","chalandiPlates","tibetanBowl152","tibetanBowl140","wineGlass","smallHandbell","albertClockBellBelfast","woodBlock"]
toUpperName (x:xs) = toUpper x : xs

-- scrapePatch 

scrapeRelease :: (D, D) -> D -> D
scrapeRelease (amp, cps) rel = (0.85 * rel * amp) * amp + rel - (cps / 10000)

scrapeFast k m = Patch 
	{ patchInstr = \x@(amp, cps) -> (mul (sig amp * k * fades 0.02 (scrapeRelease x 0.25)) . at fromMono . C.scrapeModes m) (sig cps)
	, patchFx    = return . largeHall2
	, patchMix   = 0.15 }

scrape k m = Patch 
	{ patchInstr = \x@(amp, cps) -> (mul (sig amp * k * fades 0.5 (scrapeRelease x 0.97)) . at fromMono . C.scrapeModes m) (sig cps)
	, patchFx    = return . largeHall2
	, patchMix   = 0.15 }

scrapePad k m = Patch 
	{ patchInstr = \x@(amp, cps) -> (mul (sig amp * k * fades 0.5 (scrapeRelease x 2.27	)) . at fromMono . C.scrapeModes m) (sig cps)
	, patchFx    = return . largeHall2
	, patchMix   = 0.15 }

scaleScrapeDahina = 1.32
scaleScrapeBanyan = 0.95
scaleScrapeXylophone = 1
scaleScrapeTibetanBowl180 = 0.55
scaleScrapeSpinelSphere = 1.4
scaleScrapePotLid = 0.65
scaleScrapeRedCedarWoodPlate = 1
scaleScrapeTubularBell = 0.75
scaleScrapeRedwoodPlate = 1
scaleScrapeDouglasFirWoodPlate = 1
scaleScrapeUniformWoodenBar = 1
scaleScrapeUniformAluminumBar = 0.75
scaleScrapeVibraphone1 = 0.9
scaleScrapeVibraphone2 = 0.9
scaleScrapeChalandiPlates = 1
scaleScrapeTibetanBowl152 = 0.65
scaleScrapeTibetanBowl140 = 0.75
scaleScrapeWineGlass = 0.6
scaleScrapeSmallHandbell = 1
scaleScrapeAlbertClockBellBelfast = 0.5
scaleScrapeWoodBlock = 1.32

scrapeDahina = scrape scaleScrapeDahina C.dahinaModes
scrapeBanyan = scrape scaleScrapeBanyan C.banyanModes
scrapeXylophone = scrape scaleScrapeXylophone C.xylophoneModes
scrapeTibetanBowl180 = scrape scaleScrapeTibetanBowl180 C.tibetanBowlModes180
scrapeSpinelSphere = scrape scaleScrapeSpinelSphere C.spinelSphereModes
scrapePotLid = scrape scaleScrapePotLid C.potLidModes
scrapeRedCedarWoodPlate = scrape scaleScrapeRedCedarWoodPlate C.redCedarWoodPlateModes
scrapeTubularBell = scrape scaleScrapeTubularBell C.tubularBellModes
scrapeRedwoodPlate = scrape scaleScrapeRedwoodPlate C.redwoodPlateModes
scrapeDouglasFirWoodPlate = scrape scaleScrapeDouglasFirWoodPlate C.douglasFirWoodPlateModes
scrapeUniformWoodenBar = scrape scaleScrapeUniformWoodenBar C.uniformWoodenBarModes
scrapeUniformAluminumBar = scrape scaleScrapeUniformAluminumBar C.uniformAluminumBarModes
scrapeVibraphone1 = scrape scaleScrapeVibraphone1 C.vibraphoneModes1
scrapeVibraphone2 = scrape scaleScrapeVibraphone2 C.vibraphoneModes2
scrapeChalandiPlates = scrape scaleScrapeChalandiPlates C.chalandiPlatesModes
scrapeTibetanBowl152 = scrape scaleScrapeTibetanBowl152 C.tibetanBowlModes152
scrapeTibetanBowl140 = scrape scaleScrapeTibetanBowl140 C.tibetanBowlModes140
scrapeWineGlass = scrape scaleScrapeWineGlass C.wineGlassModes
scrapeSmallHandbell = scrape scaleScrapeSmallHandbell C.smallHandbellModes
scrapeAlbertClockBellBelfast = scrape scaleScrapeAlbertClockBellBelfast C.albertClockBellBelfastModes
scrapeWoodBlock = scrape scaleScrapeWoodBlock C.woodBlockModes

scrapeFastDahina = scrapeFast scaleScrapeDahina C.dahinaModes
scrapeFastBanyan = scrapeFast scaleScrapeBanyan C.banyanModes
scrapeFastXylophone = scrapeFast scaleScrapeXylophone C.xylophoneModes
scrapeFastTibetanBowl180 = scrapeFast scaleScrapeTibetanBowl180 C.tibetanBowlModes180
scrapeFastSpinelSphere = scrapeFast scaleScrapeSpinelSphere C.spinelSphereModes
scrapeFastPotLid = scrapeFast scaleScrapePotLid C.potLidModes
scrapeFastRedCedarWoodPlate = scrapeFast scaleScrapeRedCedarWoodPlate C.redCedarWoodPlateModes
scrapeFastTubularBell = scrapeFast scaleScrapeTubularBell C.tubularBellModes
scrapeFastRedwoodPlate = scrapeFast scaleScrapeRedwoodPlate C.redwoodPlateModes
scrapeFastDouglasFirWoodPlate = scrapeFast scaleScrapeDouglasFirWoodPlate C.douglasFirWoodPlateModes
scrapeFastUniformWoodenBar = scrapeFast scaleScrapeUniformWoodenBar C.uniformWoodenBarModes
scrapeFastUniformAluminumBar = scrapeFast scaleScrapeUniformAluminumBar C.uniformAluminumBarModes
scrapeFastVibraphone1 = scrapeFast scaleScrapeVibraphone1 C.vibraphoneModes1
scrapeFastVibraphone2 = scrapeFast scaleScrapeVibraphone2 C.vibraphoneModes2
scrapeFastChalandiPlates = scrapeFast scaleScrapeChalandiPlates C.chalandiPlatesModes
scrapeFastTibetanBowl152 = scrapeFast scaleScrapeTibetanBowl152 C.tibetanBowlModes152
scrapeFastTibetanBowl140 = scrapeFast scaleScrapeTibetanBowl140 C.tibetanBowlModes140
scrapeFastWineGlass = scrapeFast scaleScrapeWineGlass C.wineGlassModes
scrapeFastSmallHandbell = scrapeFast scaleScrapeSmallHandbell C.smallHandbellModes
scrapeFastAlbertClockBellBelfast = scrapeFast scaleScrapeAlbertClockBellBelfast C.albertClockBellBelfastModes
scrapeFastWoodBlock = scrapeFast scaleScrapeWoodBlock C.woodBlockModes

scrapePadDahina = scrapePad scaleScrapeDahina C.dahinaModes
scrapePadBanyan = scrapePad scaleScrapeBanyan C.banyanModes
scrapePadXylophone = scrapePad scaleScrapeXylophone C.xylophoneModes
scrapePadTibetanBowl180 = scrapePad scaleScrapeTibetanBowl180 C.tibetanBowlModes180
scrapePadSpinelSphere = scrapePad scaleScrapeSpinelSphere C.spinelSphereModes
scrapePadPotLid = scrapePad scaleScrapePotLid C.potLidModes
scrapePadRedCedarWoodPlate = scrapePad scaleScrapeRedCedarWoodPlate C.redCedarWoodPlateModes
scrapePadTubularBell = scrapePad scaleScrapeTubularBell C.tubularBellModes
scrapePadRedwoodPlate = scrapePad scaleScrapeRedwoodPlate C.redwoodPlateModes
scrapePadDouglasFirWoodPlate = scrapePad scaleScrapeDouglasFirWoodPlate C.douglasFirWoodPlateModes
scrapePadUniformWoodenBar = scrapePad scaleScrapeUniformWoodenBar C.uniformWoodenBarModes
scrapePadUniformAluminumBar = scrapePad scaleScrapeUniformAluminumBar C.uniformAluminumBarModes
scrapePadVibraphone1 = scrapePad scaleScrapeVibraphone1 C.vibraphoneModes1
scrapePadVibraphone2 = scrapePad scaleScrapeVibraphone2 C.vibraphoneModes2
scrapePadChalandiPlates = scrapePad scaleScrapeChalandiPlates C.chalandiPlatesModes
scrapePadTibetanBowl152 = scrapePad scaleScrapeTibetanBowl152 C.tibetanBowlModes152
scrapePadTibetanBowl140 = scrapePad scaleScrapeTibetanBowl140 C.tibetanBowlModes140
scrapePadWineGlass = scrapePad scaleScrapeWineGlass C.wineGlassModes
scrapePadSmallHandbell = scrapePad scaleScrapeSmallHandbell C.smallHandbellModes
scrapePadAlbertClockBellBelfast = scrapePad scaleScrapeAlbertClockBellBelfast C.albertClockBellBelfastModes
scrapePadWoodBlock = scrapePad scaleScrapeWoodBlock C.woodBlockModes

------------------------------------
-- woodwind

data Wind = Wind 
	{ windAtt :: D
	, windDec :: D
	, windSus :: D	
	, windVib :: D	
	, windBright :: D
	}

woodWind' spec instr = Patch 
	{ patchInstr = \(amp, cps) -> mul 1.3 $ do 
		seed <- rnd 1
		vibDisp <- rnd (0.1 * amp)
		let dispVib vib = vib * (0.9 + vibDisp)		
		return $ fromMono $ mul (sig amp * fadeOut (windDec spec)) $ instr seed (dispVib $ windVib spec) (windAtt spec) (windSus spec) (windDec spec) (0.4 + 0.75 * windBright spec * amp) cps
	, patchFx = return . smallHall2
	, patchMix = 0.25
	}

-- flute

fluteSpec bright vib = Wind 
	{ windAtt = 0.08
	, windDec = 0.1
	, windSus = 20
	, windVib = vib
	, windBright = bright
	}

shortFluteSpec bright vib = Wind 
	{ windAtt = 0.03
	, windDec = 0.05
	, windSus = 20
	, windVib = vib
	, windBright = bright
	}

flute = woodWind' (fluteSpec br vib) C.flute
	where 
		br = 0.7
		vib = 0.015

shortFlute = woodWind' (shortFluteSpec br vib) C.flute
	where 
		br = 0.7
		vib = 0.015

fluteVibrato = woodWind' (fluteSpec br vib) C.flute
	where 
		br = 0.7
		vib = 0.04

mutedFlute = woodWind' (fluteSpec br vib) C.flute
	where 
		br = 0.25
		vib = 0.015

brightFlute = woodWind' (fluteSpec br vib) C.flute
	where 
		br = 1.2
		vib = 0.015

-- bass clarinet

bassClarinetSpec bright vib = Wind 
	{ windAtt = 0.06
	, windDec = 0.15
	, windSus = 20
	, windVib = vib
	, windBright = bright
	}

shortBassClarinetSpec bright vib = Wind 
	{ windAtt = 0.03
	, windDec = 0.04
	, windSus = 20
	, windVib = vib
	, windBright = bright
	}

bassClarinet = woodWind' (bassClarinetSpec br vib) C.bassClarinet
	where 
		br = 0.7
		vib = 0.01

shortBassClarinet = woodWind' (shortBassClarinetSpec br vib) C.bassClarinet
	where 
		br = 0.7
		vib = 0.01

bassClarinetVibrato = woodWind' (bassClarinetSpec br vib) C.bassClarinet
	where 
		br = 0.7
		vib = 0.035

mutedBassClarinet = woodWind' (bassClarinetSpec br vib) C.bassClarinet
	where 
		br = 0.25
		vib = 0.01

brightBassClarinet = woodWind' (bassClarinetSpec br vib) C.bassClarinet
	where 
		br = 1.2
		vib = 0.01

-- french horn

frenchHornSpec bright vib = Wind 
	{ windAtt = 0.08
	, windDec = 0.25
	, windSus = 20
	, windVib = vib
	, windBright = bright
	}

shortFrenchHornSpec bright vib = Wind 
	{ windAtt = 0.03
	, windDec = 0.04
	, windSus = 20
	, windVib = vib
	, windBright = bright
	}

frenchHorn = woodWind' (frenchHornSpec br vib) C.frenchHorn
	where 
		br = 0.7
		vib = 0.01

shortFrenchHorn = woodWind' (shortFrenchHornSpec br vib) C.frenchHorn
	where 
		br = 0.7
		vib = 0.01

frenchHornVibrato = woodWind' (frenchHornSpec br vib) C.frenchHorn
	where 
		br = 0.7
		vib = 0.035

mutedFrenchHorn = woodWind' (frenchHornSpec br vib) C.frenchHorn
	where 
		br = 0.25
		vib = 0.01

brightFrenchHorn = woodWind' (frenchHornSpec br vib) C.frenchHorn
	where 
		br = 1.2
		vib = 0.01

-- sheng

shengSpec bright vib = Wind 
	{ windAtt = 0.1
	, windDec = 0.2
	, windSus = 20
	, windVib = vib
	, windBright = bright
	}

shortShengSpec bright vib = Wind 
	{ windAtt = 0.03
	, windDec = 0.04
	, windSus = 20
	, windVib = vib
	, windBright = bright
	}

sheng = woodWind' (shengSpec br vib) C.sheng
	where 
		br = 0.7
		vib = 0.01

shortSheng = woodWind' (shortShengSpec br vib) C.sheng
	where 
		br = 0.7
		vib = 0.01

shengVibrato = woodWind' (shengSpec br vib) C.sheng
	where 
		br = 0.7
		vib = 0.025

mutedSheng = woodWind' (shengSpec br vib) C.sheng
	where 
		br = 0.25
		vib = 0.01

brightSheng = woodWind' (shortShengSpec br vib) C.sheng
	where 
		br = 1.2
		vib = 0.01

-- hulusi

hulusiSpec bright vib = Wind 
	{ windAtt = 0.12
	, windDec = 0.14
	, windSus = 20
	, windVib = vib
	, windBright = bright
	}

shortHulusiSpec bright vib = Wind 
	{ windAtt = 0.03
	, windDec = 0.04
	, windSus = 20
	, windVib = vib
	, windBright = bright
	}

hulusi = woodWind' (hulusiSpec br vib) C.hulusi
	where 
		br = 0.7
		vib = 0.015

shortHulusi = woodWind' (shortHulusiSpec br vib) C.hulusi
	where 
		br = 0.7
		vib = 0.015

hulusiVibrato = woodWind' (hulusiSpec br vib) C.hulusi
	where 
		br = 0.7
		vib = 0.035

mutedHulusi = woodWind' (hulusiSpec br vib) C.hulusi
	where 
		br = 0.25
		vib = 0.015

brightHulusi = woodWind' (shortHulusiSpec br vib) C.hulusi
	where 
		br = 1.2
		vib = 0.015


-- dizi

diziSpec bright vib = Wind 
	{ windAtt = 0.03
	, windDec = 0.2
	, windSus = 20
	, windVib = vib
	, windBright = bright
	}

shortDiziSpec bright vib = Wind 
	{ windAtt = 0.1
	, windDec = 0.04
	, windSus = 20
	, windVib = vib
	, windBright = bright
	}

dizi = woodWind' (diziSpec br vib) C.dizi
	where 
		br = 0.7
		vib = 0.01

shortDizi = woodWind' (shortDiziSpec br vib) C.dizi
	where 
		br = 0.7
		vib = 0.01

diziVibrato = woodWind' (diziSpec br vib) C.dizi
	where 
		br = 0.7
		vib = 0.035

mutedDizi = woodWind' (diziSpec br vib) C.dizi
	where 
		br = 0.25
		vib = 0.01

brightDizi = woodWind' (shortDiziSpec br vib) C.dizi
	where 
		br = 1.2
		vib = 0.01

------------------------------------
-- x-rays

pulseWidth = Patch
	{ patchInstr = mul 0.75 . at fromMono . mul (fades 0.07 0.1). onCps (uncurry C.pulseWidth)
	, patchFx    = return . smallHall2
	, patchMix   = 0.15
	}

xanadu = Patch
	{ patchInstr = mul 1.2 . at fromMono . mul (fades 0.01 2.2). onCps C.xanadu1
	, patchFx    = return . largeHall2
	, patchMix   = 0.27
	}

alienIsAngry =  Patch
	{ patchInstr = at fromMono . mul (fades 0.01 2.3). onCps (C.fmMod 5)
	, patchFx    = return . smallRoom2
	, patchMix   = 0.15
	}

noiz =  Patch
	{ patchInstr = at fromMono . mul (3 * fades 0.01 0.5). onCps C.noiz
	, patchFx    = return . smallHall2
	, patchMix   = 0.15
	}

blue = Patch
	{ patchInstr = at fromMono . mul (3 * fades 0.01 0.5). onCps (C.blue 5 7 0.24 12)
	, patchFx    = return . smallHall2
	, patchMix   = 0.25
	}

black = Patch
	{ patchInstr = at fromMono . mul (3 * fades 0.01 0.5). onCps (\cps -> C.black 3 (cps / 2) (cps * 2) 12 (sig cps))
	, patchFx    = return . smallHall2
	, patchMix   = 0.25
	}

simpleMarimba = Patch
	{ patchInstr = at fromMono . mul (1.25 * fades 0.01 0.5). onCps (C.simpleMarimba 5)
	, patchFx    = return . smallHall2
	, patchMix   = 0.25
	}

okComputer = Patch
	{ patchInstr = \(amp, cps) -> (at fromMono . mul (sig amp * fades 0.01 0.01) . at (mlp (1500 + sig amp * 8500) 0.1) . (C.okComputer . (/ 25))) (sig cps)
	, patchFx    = return 
	, patchMix   = 0.25
	}

------------------------------------
-- vowels

robotVowels vows latVow = Patch
	{ patchInstr = at fromMono . mul (fades 0.1 0.1). onCps (C.vowels 25 vows latVow)
	, patchFx    = return . smallHall2
	, patchMix   = 0.15
	}

robotLoopVowels loopDur vows = Patch
	{ patchInstr = at fromMono . mul (fades 0.1 0.1). onCps (C.loopVowels 25 loopDur vows)
	, patchFx    = return . smallHall2
	, patchMix   = 0.15
	}

robotVowel vow = Patch
	{ patchInstr = at fromMono . mul (fades 0.1 0.1). onCps (C.oneVowel 25 vow)
	, patchFx    = return . smallHall2
	, patchMix   = 0.15
	}

------------------------------------
-- nature / effects

windWall = Patch
	{ patchInstr = at fromMono . mul (1.25 * fades 0.1 5). onCps C.windWall
	, patchFx    = return . largeHall2
	, patchMix   = 0.25
	}

mildWind = Patch
	{ patchInstr = at fromMono . mul (1.25 * fades 0.1 1.5). onCps C.mildWind
	, patchFx    = return . largeHall2
	, patchMix   = 0.25
	}

wind = Patch
	{ patchInstr = at fromMono . mul (0.7 * fades 0.1 1.5). onCps (\cps -> T.wind (cps * 2) 150 (0.3, 1))
	, patchFx    = return . largeHall2
	, patchMix   = 0.25
	}

------------------------------------
-- drums

