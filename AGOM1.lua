-- --------- --
-- Constants --
-- --------- --

pattern_length = 64
number_of_patterns = 10

-- Set random seed
math.randomseed(1)

-- Set of bass notes
bass_notes = {}
for bn=20,40 do
   bass_notes[bn] = true
end

-- Set of mid notes
mid_notes = {}
for mn=40,60 do
   mid_notes[mn] = true
end

-- Set of high notes
high_notes = {}
for tn=80,100 do
   high_notes[tn] = true
end

-- This function returns a uniform distribution of note triples
function uniformDistro()
   -- Fill result (the table mapping triples to probability)
   -- Set length of the result table
   local total_length = 0
   local result = {}
   for bn,_ in pairs(bass_notes) do
      for mn,_ in pairs(mid_notes) do
         for tn,_ in pairs(high_notes) do
            total_length = total_length + 1
            local triple = {bass_note = bn, mid_note = mn, high_note = tn}
            result[triple] = 1
         end
      end
   end

   -- Normalize so the probability sums up to 1
   for triple, prob in pairs(result) do
      result[triple] = prob / total_length
   end

   return result
end
uniDistro = uniformDistro()

-- ----------------- --
-- Generic functions --
-- ----------------- --

-- Return the size of a table
function length(t)
   local len = 0
   for _,_  in pairs(t) do
      len = len + 1
   end
   return len
end

-- Return true iff A is a subset (not scrict) of B. Note that keys
-- only are considered.
function subset(A, B)
   for k,_ in pairs(A) do
      if B[k] == nil then
         return false
      end
   end
   return true
end

-- ---------------------- --
-- Generic note functions --
-- ---------------------- --

-- Recall:
--
-- Note integer is in [0-119], 120 == Off, 121=Empty
--
-- Corresponding to the note strings ['C-0'-'G-9'], 'OFF', '---'

-- Return the octave of a note (0 to 9), that note can be represented
-- as an int or string
function get_octave(note)
   if type(note) == 'number' then
      return math.floor(note / 12)
   elseif type(note) == 'string' then
      return tonumber(string.sub(s,-1,-1))
   end
end

-- Return pitch class given a note int or string. There are 12 pitch
-- classes, 0 being C, 12 being B.
function get_pitch_class(note)
   if type(note) == 'number' then
      return note % 12
   elseif type(note) == 'string' then
      assert(false, "Not implement")
      return 0
   end
end

function get_freq(note)
   return 440 * 2^((note - 48)/12)
end

-- Convert pitch class into string
function pc2Str(pitch_class)
   if pitch_class == 0 then return "C-" end
   if pitch_class == 1 then return "C#" end
   if pitch_class == 2 then return "D-" end
   if pitch_class == 3 then return "D#" end
   if pitch_class == 4 then return "E-" end
   if pitch_class == 5 then return "F-" end
   if pitch_class == 6 then return "F#" end
   if pitch_class == 7 then return "G-" end
   if pitch_class == 8 then return "G#" end
   if pitch_class == 9 then return "A-" end
   if pitch_class == 10 then return "A#" end
   if pitch_class == 11 then return "B-" end
end

-- Convert int note representation into string
function noteInt2Str(note)
   return pc2Str(get_pitch_class(note)) .. get_octave(note)
end

-- Convert string note representation into int
function noteStr2Int(note)
   return get_octave(note) * 12 + get_pitch_class(note)
end

----------------------------------
-- Generic Stockastic functions --
----------------------------------

-- Return a normalized distribution (if it isn't already)
function normalizeDistro(distro)
   local total = 0
   for _, prob in pairs(distro) do
      total = total + prob
   end
   local res = {}
   for triple, prob in pairs(distro) do
      res[triple] = prob / total
   end
   return res
end

-- Return the normalized product of a tuple of distributions
function prodDistros(distro1, ...)
   local result = {}
   local arg = {...}
   for triple, prob in pairs(distro1) do
      prodProb = 1
      for i, distro in pairs(arg) do
         prodProb = prodProb * distro[triple]
      end
      result[triple] = prodProb
   end
   return normalizeDistro(result)
end

-- Return weighted average of distro1 and distro2. if weight = 0 then
-- distro1 is returned, if weight = 1 then distro2 is returned, if
-- weight = 0.5 the average between distro1 and distro2 is return
function mixDistros(distro1, distro2, weight)
   if weight == 0 then
      return distro1
   elseif weight == 1 then
      return distro2
   else
      local result = {}
      for triple, prob in pairs(distro1) do
         result[triple] = prob * (1 - weight) + distro2[triple] * weight
      end
      return result
   end
end

-- Takes a distribution and return a uniformized one, basically it
-- does a weighted average between that distribution and the uniform
-- distribution. degree is in [0,1], 0 meaning the distribution hasn't
-- changed, 1 meaning it is uniform
function uniformizeDistro(distro, degree)
   return mixDistros(distro, uniDistro, degree)
end

-- Given a distribution, pick up a triple
function sample(distro)
   local position = math.random()
   local prob_sum = 0
   for triple, prob in pairs(distro) do
      if prob_sum <= position then         
         prob_sum = prob_sum + prob
         if position < prob_sum then
            return triple
         end
      end
   end
   error("There must be a bug")
end

-- ------------------ --
-- Specific functions --
-- ------------------ --

-- 1. Conjunct melodic motion

function conjunctMelodicMotion(context)
   if context.prev_triple == nil then
      return uniDistro
   else
      local result = {}
      local prev_triple = context.prev_triple
      for triple, _ in pairs(uniDistro) do
         -- The probability for each note decreases linearily, for the
         -- 10 +/- semintone neighbors of the previous notes. The
         -- probability of the triplet is the product of the
         -- individual note's probabilities.

         -- The probabilities are unormalized for now
         local bDst = math.abs(triple.bass_note - prev_triple.bass_note)
         local bProb = math.max(0, 11 - bDst)
         local mDst = math.abs(triple.mid_note - prev_triple.mid_note)
         local mProb = math.max(0, 11 - mDst)
         local hDst = math.abs(triple.high_note - prev_triple.high_note)
         local hProb = math.max(0, 11 - hDst)
         result[triple] = bProb * mProb * hProb
      end
      return normalizeDistro(result)
   end
end

-- 2. Acoustic consonance

function pairwiseAC(noteA, noteB)
   -- We use the trick (A+B)/AB, where A and B represent the ratios of
   -- noteA and noteB. This trick has been found here
   -- http://music.stackexchange.com/questions/4439/is-there-a-way-to-measure-the-consonance-or-dissonance-of-a-chord
   local A = get_freq(noteA) / get_freq(noteB)
   local B = get_freq(noteB) / get_freq(noteA)
   return (A + B) / (A * B)
end

function acousticConsonance(context)
   local result = {}
   for triple, _ in pairs(uniDistro) do
      -- The probability of a triple is proportional to the average
      -- consonance of all pairs of notes (hmm, maybe it should be the
      -- product, not the average)
      local BMC = pairwiseAC(triple.bass_note, triple.mid_note)
      local BHC = pairwiseAC(triple.bass_note, triple.high_note)
      local MHC = pairwiseAC(triple.mid_note, triple.high_note)
      result[triple] = (BMC + BHC + MHC) / 3
   end
   return normalizeDistro(result)
end

-- 3. Harmony consistency

function harmonyConsistency(context)
   -- TODO
   return uniDistro
end

-- 4. Limited macroharmony

-- Set the notes of the limited macroharmony distribution. This one
-- could evolve with time but for now it is constant

-- Number of notes in the limited macroharmony set
limited_macroharmony_length = math.random(5, 8)

-- Pick up the number of pitch classes
limited_macroharmony_pitch_classes = {}
while length(limited_macroharmony_pitch_classes) < limited_macroharmony_length do
   limited_macroharmony_pitch_classes[math.random(1,12)] = true
end

function limitedMacroharmony(context)
   local result = {}
   for triple,_ in pairs(uniDistro) do
      local bn_pitch_class = get_pitch_class(triple.bass_note)
      local mn_pitch_class = get_pitch_class(triple.mid_note)
      local hn_pitch_class = get_pitch_class(triple.high_note)
      local t = {}
      t[bn_pitch_class] = true
      t[mn_pitch_class] = true
      t[hn_pitch_class] = true
      if subset(t, limited_macroharmony_pitch_classes) then
         result[triple] = 1
      else
         result[triple] = 0         
      end
   end
   return normalizeDistro(result)
end

-- 5. Centricity

-- Select the pitch_class centricity
centricity_pitch_class_index = math.random(limited_macroharmony_length)
i = 1
for pc,_ in pairs(limited_macroharmony_pitch_classes) do
   if i == centricity_pitch_class_index then
      centricity_pitch_class = pc
      break
   end
   i = i + 1
end

-- Define the centricity bias in term how much time the centric pitch
-- class has its probability boosted compared to the other pitch
-- classes.
centricity_bias = 1.5

function centricity(context)
   local result = {}
   for triple,_ in pairs(uniDistro) do
      local bn_pitch_class = get_pitch_class(triple.bass_note)
      local mn_pitch_class = get_pitch_class(triple.mid_note)
      local hn_pitch_class = get_pitch_class(triple.high_note)
      local prob = 0

      if bn_pitch_class == centricity_pitch_class then
         prob = prob + centricity_bias
      else
         prob = prob + 1
      end

      if mn_pitch_class == centricity_pitch_class then
         prob = prob + centricity_bias
      else
         prob = prob + 1
      end

      if hn_pitch_class == centricity_pitch_class then
         prob = prob + centricity_bias
      else
         prob = prob + 1
      end

      result[triple] = prob
   end
   return normalizeDistro(result)
end

-- This function takes
--
-- 1) a context, like the N previous notes
--
-- 2) a modulator, a record of the intensities of all constraints
--
-- Returns a table mapping each triple of notes (Bass, Mid, High) into
-- a probability
function finalDistro(context, modulator)
   -- Compute the distro of each constraint
   conjunctMelodicMotionDistro = conjunctMelodicMotion(context)
   acousticConsonanceDistro = acousticConsonance(context)
   limitedMacroharmonyDistro = limitedMacroharmony(context)
   centricityDistro = centricity(context)

   -- Mix each of them with the uniform distribution, depending on its
   -- intensity (controlled by the modulator)
   conjunctMelodicMotionDM = uniformizeDistro(conjunctMelodicMotionDistro,
                                              1 - modulator.conjunctMelodicMotion)

   acousticConsonanceDM = uniformizeDistro(acousticConsonanceDistro,
                                           1 - modulator.acousticConsonance)
                                           
   limitedMacroharmonyDM = uniformizeDistro(limitedMacroharmonyDistro,
                                            1 - modulator.limitedMacroharmony)
                                            
   centricityDM = uniformizeDistro(centricityDistro,
                                   1 - modulator.centricity)
   
   

   return normalizeDistro(prodDistros(conjunctMelodicMotionDM,
                                      acousticConsonanceDM,
                                      limitedMacroharmonyDM,
                                      centricityDM))
end

-- Fade in the modulators, one by one, during each even pattern.
function updateModulator(modulator, pi, li)
   if pi == 1 then
      modulator.conjunctMelodicMotion = 0
      modulator.acousticConsonance = 0
      modulator.harmonyConsistency = 0
      modulator.limitedMacroharmony = 0
      modulator.centricity = 0
   elseif pi == 2 then
      modulator.conjunctMelodicMotion = li / pattern_length
   elseif pi == 4 then
      modulator.acousticConsonance = li / pattern_length
   elseif pi == 6 then
      modulator.limitedMacroharmony = li / pattern_length
   elseif pi == 8 then
      modulator.centricity = li / pattern_length
   end
end

-- ---- --
-- Main --
-- ---- --

context = {}                 -- Hold the previous triplet of notes
modulator = {}               -- Control the intensity of each contraint over time

for pi=1,number_of_patterns do
   for li=1,pattern_length do
      -- Update modulator
      updateModulator(modulator, pi, li)

      -- -- Write modulator
      -- print("conjunctMelodicMotion =",
      --       modulator.conjunctMelodicMotion,
      --       "acousticConsonance =",
      --       modulator.acousticConsonance,
      --       "harmonyConsistency =",
      --       modulator.harmonyConsistency,
      --       "limitedMacroharmony =",
      --       modulator.limitedMacroharmony,
      --       "modulator.centricity =",
      --       modulator.centricity)

      -- Distribution of the next note triple
      local distro = finalDistro(context, modulator)

      -- -- Display distribution (for debugging)
      -- for triple, prob in pairs(distribution) do
      --    print(triple, prob)
      -- end
   
      -- Sample triple according to that distribution
      local triple = sample(distro)

      -- Write it down
      print("(", pi, li, ")",
            " Bass note = ", noteInt2Str(triple.bass_note),
            ", Mid note = ", noteInt2Str(triple.mid_note),
            ", High note = ", noteInt2Str(triple.high_note))

      -- Renoise it down
      -- TODO

      -- Update the context
      context.prev_triple = triple
   end
end
