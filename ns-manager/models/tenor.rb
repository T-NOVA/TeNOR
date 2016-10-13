class Tenor
    include Mongoid::PrefixableDocument # ...instead of Mongoid::Document
    include Mongoid::Timestamps
    field :module, type: String
    field :severity, type: String
    field :msg, type: String
    index({ name: 1 }, unique: true)

    freeze_stack! # this needs to be the last line in your model!
  end
