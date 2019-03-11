define :convert_tab do |tab, bar_len|
  lines = tab.split("\n")[1..-1]
  # Classifier lines as part of the tab (strings) or not
  lines_class = lines.collect{ |x|
    x.include? "-" and x.include? "|" and not x[0] == " "
  }
  puts lines_class
  first_string_index = lines_class.index(true)
  num_strings = (if lines_class.include? false
                 then (if lines_class[first_string_index..-1].include? false
                       then lines_class[first_string_index..-1].index(false)
                       else lines_class[first_string_index..-1].length
                   end)
                 else lines_class.length
  end)
  puts num_strings
  string_notes = lines[first_string_index..(num_strings + first_string_index - 1)].collect{|x|
    x[0..x.index('|')-1]
  }
  bars_lines = lines.select{ |x|
    x.include? "-" and x.include? "|" and not x[0] == " "
  }
  bars_lines = bars_lines.collect{|x| x[bars_lines[0].index('|')..-1]}
  
  if string_notes == ["G","D","A","E"]
    string_notes = ["G3","D3","A2","E2"]
  end
  if string_notes == ["E","B","G","D","A","E"] or string_notes == ["e","B","G","D","A","E"]
    string_notes = ["E5","B4","G4","D4","A3","E3"]
  end
  puts string_notes
  string_tab = [].replace(string_notes)
  
  # Join bars corresponding to the same string
  for i in 0..(bars_lines.length - 1)
    string_no = i % num_strings
    string_tab[string_no] += bars_lines[i]
  end
  
  # Convert tabs as string to array of notes
  sixteenths = string_tab.each_with_index.map{ |x,i|
    x[x.index('|')..-1]
    .tr('|','')
    .split('')
    .collect{ |y|
      if y == ' '
        'X'
      else
        if not ['-','h','p','/','^','\\','b','r','(',')','~','x',' '].include? y
          (note(string_notes[i]) + y.to_i)
        else
          '-'
        end
      end
    }
  }
  sixteenths = sixteenths.collect{|x|
    x - ["X"]
  }
  
  # Correct frets >= 10
  for j in 0..sixteenths.length-1
    open_string = note(string_notes[j])
    string = sixteenths[j]
    for i in 1..string.length-1
      current_char = string[i]
      prev_char = string[i-1]
      if prev_char.is_a? Numeric
        if current_char.is_a? Numeric
          string[i-1] = 10*(string[i-1]-open_string) + current_char
          string[i] = '-'
        end
      end
    end
  end
  
  
  # Put in time order and remove rests
  header, *rows = sixteenths
  sixteenths_zipped = header.zip(*rows).collect{ |x|
    x - ["-"]
  }
  
  part = [[],[]] # [notes,durations]
  iota = bar_len.to_f / bars_lines[0][1..-1].index('|')
  current_notes = (if sixteenths_zipped[0] == [] then nil else sixteenths_zipped[0] end)
  current_duration = iota
  for x in sixteenths_zipped[1..-1]
    if x != []
      # add previous notes
      part[0] << current_notes
      part[1] << current_duration
      # log new notes
      current_notes = x
      current_duration = 0
    end
    current_duration += iota
  end
  part[0] << current_notes
  part[1] << current_duration
  return part
end

define :play_tab do |tab, bar_length, amp|
  bass = convert_tab(tab, bar_length)
  puts bass
  play_pattern_timed bass[0],bass[1], amp: amp, release: 0.1
end

##| ^ Henry's tab stuff ^
##| v       Music       v

bass_tab ='
   Bb               G
G3|------------3-5-|--------5---3---|
D3|------3---------|----------3-----|
A2|1-------1-------|----------------|
E2|----------------|3---------------|
   F                Eb    
G3|------2---------|----8-----------|
D3|---3------------|----------------|
A2|-----------8--7-|6-----6---------|
E2|1--1--1---------|------------1-3-|'

chords = (ring chord(:Bb4, :add9),
          chord(:G4, :m7),
          chord(:F4, :add9),
          chord(:Eb4, :add9)) # would write out if I had > 4 mins]

live_loop :bass do
  play_tab(bass_tab, 2, 1.5)
end

live_loop :chords do
  with_fx :echo, decay: 2 do
    with_synth :zawa do
      play chords.tick, attack: 0.3, sustain: 1, release: 0.7
      sleep 2
    end
  end
end



