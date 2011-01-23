module Recurly
  class Subscription < AccountBase
    self.element_name = "subscription"

    def self.default_attributes
      [
        :plan_code,
        :unit_amount,
        :quantity,
        :trial_ends_at
      ]
    end

    # initialize fields with blank data
    def initialize(attributes = {})

      attributes[:account] ||= {}

      if attributes[:account].is_a?(Hash)
        Account.default_attributes.each do |attribute|
          attributes[:account][attribute] ||= nil
        end
      end

      attributes[:billing_info] ||= {}
      if attributes[:billing_info].is_a?(Hash)
        BillingInfo.default_attributes.each do |attribute|
          attributes[:billing_info][attribute] ||= nil
        end
      end

      attributes[:credit_card] ||= {}
      if attributes[:credit_card].is_a?(Hash)
        BillingInfo.credit_card_attributes.each do |attribute|
          attributes[:credit_card][attribute] ||= nil
        end
      end

      attributes[:addons] ||= []

      super(attributes)
    end

    def self.refund(account_code, refund_type = :partial)
      raise "Refund type must be :full, :partial, or :none." unless [:full, :partial, :none].include?(refund_type)
      Subscription.delete(nil, {:account_code => account_code, :refund => refund_type})
    end

    # Terminates the subscription immediately and processes a full or partial refund
    def refund(refund_type)
      self.class.refund(self.subscription_account_code, refund_type)
    end

    def self.cancel(account_code)
      Subscription.delete(account_code)
    end

    # Stops the subscription from renewing. The subscription remains valid until the end of
    # the current term (current_period_ends_at).
    def cancel(account_code = nil)
      unless account_code.nil?
        ActiveSupport::Deprecation.warn('Calling Recurly::Subscription#cancel with an account_code has been deprecated. Use the static method Recurly::Subscription.cancel(account_code) instead', caller)
      end
      self.class.cancel(account_code || self.subscription_account_code)
    end

    def self.reactivate(account_code, options = {})
      path = "/accounts/#{CGI::escape(account_code.to_s)}/subscription/reactivate"
      connection.post(path, "", headers)
    rescue ActiveResource::Redirection => e
      return true
    end

    def reactivate
      self.class.reactivate(self.subscription_account_code)
    end

    # Valid timeframe: :now or :renewal
    # Valid options: plan_code, quantity, unit_amount
    def change(timeframe, options = {})
      raise "Timeframe must be :full or :renewal." unless timeframe == 'now' or timeframe == 'renewal'
      options[:timeframe] = timeframe
      path = "/accounts/#{CGI::escape(self.subscription_account_code.to_s)}/subscription.xml"
      connection.put(path,
        self.class.format.encode(options, :root => :subscription),
        self.class.headers)
    end

    def subscription_account_code
      acct_code = self.account_code if defined?(self.account_code) and !self.account_code.nil? and !self.account_code.blank?
      acct_code ||= account.account_code if defined?(account) and !account.nil?
      acct_code ||= self.primary_key if defined?(self.primary_key)
      acct_code ||= self.id if defined?(self.id)
      raise 'Missing Account Code' if acct_code.nil? or acct_code.blank?
      acct_code
    end
  end
end

