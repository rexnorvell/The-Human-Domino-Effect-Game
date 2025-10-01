extends RichTextLabel

const delimiter = " " # split on space since urls don't use it

func _init(name: String = "") -> void:
#	self.text = name
	var url = curriculum.external_link_dict.get(name)
	self.bbcode_enabled = url != null
	if self.bbcode_enabled:
		self.text = "[color=blue][url=" + url + "]" + name

# Called when the node enters the scene tree for the first time.
func _ready():
	if connect("meta_clicked", Callable(self, "meta_clicked")): # if connect call fails
		print("ERROR: ExternalLink.gd failed to override meta_clicked function.")

func meta_clicked(meta: String) -> void:
	# splits in case more or less than one link is provided
	var urls = meta.split(delimiter, true)
	for url in urls:
		# TODO: <test OS.shell_open for opening links on mobile device, assuming ExternalLink.gd gets completed>
		if OS.shell_open(url): # if shell_open call fails
			print("ERROR: ExternalLink could not open link\"" + url + "\".")
