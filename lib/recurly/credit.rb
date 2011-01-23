module Recurly
  class Credit < Base
    self.element_name = "credit"
    self.prefix = "/accounts/:account_code/"

    def self.default_attributes
      [
        :amount_in_cents,
        :end_date,
        :description
      ]
    end

    def self.list(account_code)
      find(:all, :params => { :account_code => account_code })
    end

    def self.lookup(account_code, id)
      find(id, :params => { :account_code => account_code })
    end

  end
end