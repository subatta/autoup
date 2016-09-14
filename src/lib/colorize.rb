class String

	def colorize(text, color_code)
  		"\e[#{color_code}m#{text}\e[0m"
	end
	def black
	  colorize self, 30
	end
	def red
	  colorize self, 31
	end
	def green
	  colorize self, 32
	end
	def white
	  colorize self, 33
	end
	def blue
	  colorize self, 34
	end
	def magenta
	  colorize self, 35
	end
	def cyan
	  colorize self, 36
	end
	def yellow
	  colorize self, 37
	end

	def bg_black
	  colorize self, 40
	end
	def bg_red
	  colorize self, 41
	end
	def bg_green
	  colorize self, 42
    end
	def bg_white
	  colorize self, 43 
	end
	def bg_blue
	  colorize self, 44
	end
	def bg_magenta
	  colorize self, 45
	end
	def bg_cyan
	  colorize self, 46
	end
	def bg_yellow
	  colorize self, 47
	end

	def bold
	  "\e[1m#{self}\e[22m" 
	end
	def italic
		"\e[3m#{self}\e[23m" 
	end
	def underline
	  "\e[4m#{self}\e[24m" 
	end
	def blink
	  "\e[5m#{self}\e[25m" 
	end
	def reverse_color
	  "\e[7m#{self}\e[27m" 
	end
end