class Ns
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Pagination

    field :nsd, type: Hash
end

=begin
class NsSerializer
    def initialize(book)
        @book = book
    end

    def as_json(*)
        data = {
            id: @book.id.to_s,
            title: @book.title,
            author: @book.author,
            isbn: @book.isbn
        }
        data[:errors] = @book.errors if @book.errors.any?
        data
    end
end
=end
