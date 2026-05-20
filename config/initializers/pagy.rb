require "pagy/extras/metadata"
require "pagy/extras/overflow"

Pagy::DEFAULT[:limit] = 20
Pagy::DEFAULT[:overflow] = :empty_page
Pagy::DEFAULT[:metadata] = %i[page limit count pages prev next]
