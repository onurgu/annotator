# Public: Tags plugin allows users to tag thier annotations with metadata
# stored in an Array on the annotation as tags.
class Annotator.Plugin.Objects extends Annotator.Plugin

  events:
    ".twitter-annotator button click":     "onButtonClick"

  options:
    # Configurable function which accepts a string (the contents)
    # of the tags input as an argument, and returns an array of
    # tags.
    parseTags: (string) ->
      string = $.trim(string)

      tags = []
      tags = string.split(/\s+/) if string
      tags

    # Configurable function which accepts an array of tags and
    # returns a string which will be used to fill the tags input.
    stringifyTags: (array) ->
      array.join(" ")

  # The field element added to the Annotator.Editor wrapped in jQuery. Cached to
  # save having to recreate it everytime the editor is displayed.
  personField: null
  locationField: null
  actionField: null

  # The input element added to the Annotator.Editor wrapped in jQuery. Cached to
  # save having to recreate it everytime the editor is displayed.
  personInput: null
  locationInput: null
  actionInput: null

  # Public: Initialises the plugin and adds custom fields to both the
  # annotator viewer and editor. The plugin also checks if the annotator is
  # supported by the current browser.
  #
  # Returns nothing.
  pluginInit: ->
    return unless Annotator.supported()

    self = this
    updateField = (objectType) ->
      (field, annotation) -> self.updateField(field, annotation, objectType)
    updateViewer = (objectType) ->
      (field, annotation) -> self.updateViewer(field, annotation, objectType)
    setAnnotationTags = (objectType) ->
      (field, annotation) -> self.setAnnotationTags(field, annotation, objectType)

    @personField = @annotator.editor.addField({
      label:  Annotator._t('If this is a PERSON, tag here') + '\u2026'
      load:   updateField("person")
      submit: setAnnotationTags("person")
    })

    @locationField = @annotator.editor.addField({
      label:  Annotator._t('If this is a LOCATION, tag here') + '\u2026'
      load:   updateField("location")
      submit: setAnnotationTags("location")
    })

    @actionField = @annotator.editor.addField({
      label:  Annotator._t('If this is an ACTION, tag here') + '\u2026'
      load:   updateField("action")
      submit: setAnnotationTags("action")
    })

#    @annotator.editor.addField({
#        type:   'checkbox'
#        label:  Annotator._t('Allow anyone to <strong>view</strong> this annotation')
#        load:   createCallback("alert")
#        submit: createCallback("alert")
#      })

    @annotator.viewer.addField({
      load: updateViewer("person")
    })

    @annotator.viewer.addField({
      load: updateViewer("location")
    })

    @annotator.viewer.addField({
      load: updateViewer("action")
    })

    # Add a filter to the Filter plugin if loaded.
    if @annotator.plugins.Filter
      @annotator.plugins.Filter.addFilter
        label: Annotator._t('Person')
        property: 'personTags'
        isFiltered: Annotator.Plugin.Objects.filterCallback

      @annotator.plugins.Filter.addFilter
        label: Annotator._t('Location')
        property: 'locationTags'
        isFiltered: Annotator.Plugin.Objects.filterCallback

      @annotator.plugins.Filter.addFilter
        label: Annotator._t('Action')
        property: 'actionTags'
        isFiltered: Annotator.Plugin.Objects.filterCallback

    @personInput = $(@personField).find(':input')
    @locationInput = $(@locationField).find(':input')
    @actionInput = $(@actionField).find(':input')

  # Public: Extracts tags from the provided String.
  #
  # string - A String of tags seperated by spaces.
  #
  # Examples
  #
  #   plugin.parseTags('cake chocolate cabbage')
  #   # => ['cake', 'chocolate', 'cabbage']
  #
  # Returns Array of parsed tags.
  parseTags: (string) ->
    @options.parseTags(string)

  onButtonClick: (event) ->
    console.log(event)
    @annotator.adder
        .css(Annotator.Util.mousePosition(event, @annotator.wrapper[0]))
        .show()

  # Public: Takes an array of tags and serialises them into a String.
  #
  # array - An Array of tags.
  #
  # Examples
  #
  #   plugin.stringifyTags(['cake', 'chocolate', 'cabbage'])
  #   # => 'cake chocolate cabbage'
  #
  # Returns Array of parsed tags.
  stringifyTags: (array) ->
    @options.stringifyTags(array)

  # Annotator.Editor callback function. Updates the @input field with the
  # tags attached to the provided annotation.
  #
  # field      - The tags field Element containing the input Element.
  # annotation - An annotation object to be edited.
  #
  # Examples
  #
  #   field = $('<li><input /></li>')[0]
  #   plugin.updateField(field, {tags: ['apples', 'oranges', 'cake']})
  #   field.value # => Returns 'apples oranges cake'
  #
  # Returns nothing.
  updateField: (field, annotation, objectType) =>
    value = ''

    if objectType == "person"
      value = this.stringifyTags(annotation.personTags) if annotation.personTags
      @personInput.val(value)
    else if objectType == "location"
      value = this.stringifyTags(annotation.locationTags) if annotation.locationTags
      @locationInput.val(value)
    else if objectType == "action"
      value = this.stringifyTags(annotation.actionTags) if annotation.actionTags
      @actionInput.val(value)

  # Annotator.Editor callback function. Updates the annotation field with the
  # data retrieved from the @input property.
  #
  # field      - The tags field Element containing the input Element.
  # annotation - An annotation object to be updated.
  #
  # Examples
  #
  #   annotation = {}
  #   field = $('<li><input value="cake chocolate cabbage" /></li>')[0]
  #
  #   plugin.setAnnotationTags(field, annotation)
  #   annotation.tags # => Returns ['cake', 'chocolate', 'cabbage']
  #
  # Returns nothing.
  setAnnotationTags: (field, annotation, objectType) =>
    if objectType == "person"
      annotation.personTags = this.parseTags(@personInput.val())
    else if objectType == "location"
      annotation.locationTags = this.parseTags(@locationInput.val())
    else if objectType == "action"
      annotation.actionTags = this.parseTags(@actionInput.val())

  # Annotator.Viewer callback function. Updates the annotation display with tags
  # removes the field from the Viewer if there are no tags to display.
  #
  # field      - The Element to populate with tags.
  # annotation - An annotation object to be display.
  #
  # Examples
  #
  #   field = $('<div />')[0]
  #   plugin.updateField(field, {tags: ['apples']})
  #   field.innerHTML # => Returns '<span class="annotator-tag">apples</span>'
  #
  # Returns nothing.
  updateViewer: (field, annotation, objectType) ->
    field = $(field)

    choices = [["person", annotation.personTags],
               ["location", annotation.locationTags],
               ["action", annotation.actionTags]]

    for choice in choices
      if choice[0] == objectType
        tagsArray = choice[1]

    if tagsArray and $.isArray(tagsArray) and tagsArray.length
      console.log(tagsArray)
      field.addClass('annotator-tags object-' + objectType).html(->
        string = objectType.toUpperCase() + ": " + $.map(tagsArray,(tag) ->
            '<span class="annotator-tag">' + Annotator.Util.escape(tag) + '</span>'
        ).join(' ')
      )
    else
      field.remove()

# Checks an input string of keywords against an array of tags. If the keywords
# match _all_ tags the function returns true. This should be used as a callback
# in the Filter plugin.
#
# input - A String of keywords from a input field.
#
# Examples
#
#   Tags.filterCallback('cat dog mouse', ['cat', 'dog', 'mouse']) //=> true
#   Tags.filterCallback('cat dog', ['cat', 'dog', 'mouse']) //=> true
#   Tags.filterCallback('cat dog', ['cat']) //=> false
#
# Returns true if the input keywords match all tags.
Annotator.Plugin.Objects.filterCallback = (input, tags = []) ->
  matches  = 0
  keywords = []
  if input
    keywords = input.split(/\s+/g)
    for keyword in keywords when tags.length
      matches += 1 for tag in tags when tag.indexOf(keyword) != -1

  matches == keywords.length
