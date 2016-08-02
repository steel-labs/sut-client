# Copyright (c) 2016 STEEL Ltd.
# http://steellondon.com/
#
# Written by: Giovanni Derks, Raffaele Abramini
#
# SignUpToClient is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------

require 'httparty'
require 'uuidtools'
require 'time'

class SignUpToClient
  include HTTParty

  class SubscriptionExistsError < StandardError
    attr_reader :subscription_id

    def initialize(subscription_id)
      @subscription_id = subscription_id
    end
  end

  SERVER       = 'api.sign-up.to'
  VERSION      = '1'
  STATUS_OK    = 'ok'
  STATUS_ERROR = 'error'

  def initialize(uid, cid, hash)
    @uid  = uid
    @cid  = cid
    @hash = hash

    self.class.base_uri "https://#{SERVER}/v#{VERSION}"
  end

  def get_folder(id = 0)
    endpoint = "folder#{(id > 0 ? "/#{id}" : '')}"
    request 'get', endpoint
  end

  def get_list(id = 0)
    endpoint = "list#{(id > 0 ? "/#{id}" : '')}"
    request 'get', endpoint
  end

# @param [String] subscriber_email
# @param [String] msisdn
# @param [Integer] list_id
# @return [Object] empty if the subscriber hasn't been found
  def get_subscriber(subscriber_email = '', msisdn = '', list_id = 0)

    if subscriber_email == '' && msisdn == ''
      raise 'Please specify either subscriber_email or msisdn'
    end

    attributes            = {}
    attributes['email']   = subscriber_email unless subscriber_email.empty?
    attributes['msisdn']  = msisdn unless msisdn.empty?
    attributes['list_id'] = list_id if list_id.to_i > 0


    api_res = request 'get', 'subscriber', :query => attributes

    if api_res && api_res['status'] == STATUS_OK
      res = api_res['response']['data'][0]
    elsif api_res['status'] == STATUS_ERROR && api_res['response']['code'] == 404
      res = {}
    else
      raise "Unexpected error: \n#{api_res.inspect}"
    end

    res
  end

# @param [String] subscriber_email
# @param [Integer] list_id
# @param [Boolean] confirmed
# @param [Object] subscriber_attr
  def create_subscriber(subscriber_email, list_id, confirmed = false, subscriber_attr: {})

    if subscriber_email.empty?
      raise 'Please specify the subscriber_email'
    end

    # Mandatory attributes passed as arguments
    attributes = subscriber_attr.clone
    attributes['email']     = subscriber_email
    attributes['list_id']   = list_id
    attributes['confirmed'] = confirmed ? 1 : 0

    api_res = request 'post', 'subscriber', :body => attributes

    if api_res && api_res['status'] == STATUS_OK
      res = api_res['response']['data']
    else
      raise "Unexpected error: \n#{api_res.inspect}"
    end

    res
  end

# @param [Integer] subscriber_id
# @param [Object] subscriber_attr
  def update_subscriber(subscriber_id, subscriber_attr)

    unless subscriber_id > 0
      raise 'Please specify the subscriber_id'
    end

    # Mandatory attributes passed as arguments
    attributes = subscriber_attr.clone
    attributes['id'] = subscriber_id

    api_res = request 'put', 'subscriber', :body => attributes

    if api_res && api_res['status'] == STATUS_OK
      res = api_res['response']['data'][0]
    else
      raise "Unexpected error: \n#{api_res.inspect}"
    end

    res
  end

# @param [Integer] subscription_id
# @param [Integer] subscriber_id
# @param [Integer] list_id
# @param [Nil|Boolean] confirmed
# @param [Boolean] get_first
  def get_subscription(subscription_id = 0, subscriber_id = 0, list_id = 0, confirmed = nil, get_first: true)

    attributes                  = {}
    attributes['id']            = subscription_id if subscription_id > 0
    attributes['subscriber_id'] = subscriber_id if subscriber_id > 0
    attributes['list_id']       = list_id if list_id > 0
    attributes['confirmed']     = confirmed ? 1 : 0 unless confirmed.nil?

    api_res = request 'get', 'subscription', :query => attributes

    if get_first
      if api_res && api_res['status'] == STATUS_OK
        res = api_res['response']['data'][0]
      elsif api_res['status'] == STATUS_ERROR && api_res['response']['code'] == 404
        res = {}
      else
        raise "Unexpected error: \n#{api_res.inspect}"
      end
    else
      res = api_res
    end

    res
  end

  def create_subscription(subscriber_id = 0, list_id = 0, confirmed = nil, confirmation_url: '')

    unless subscriber_id > 0 && list_id > 0
      raise 'You must provide subscriber_id AND list_id'
    end

    attributes                         = {}
    attributes['subscriber_id']        = subscriber_id
    attributes['list_id']              = list_id
    attributes['confirmed']            = confirmed ? 1 : 0 unless confirmed.nil?
    attributes['confirmationredirect'] = confirmation_url unless confirmation_url.empty?

    api_res = request 'post', 'subscription', :body => attributes

    if api_res && api_res['status'] == STATUS_OK
      res = api_res['response']['data']
    elsif api_res['status'] == STATUS_ERROR && api_res['response']['code'] == 409
      raise SubscriptionExistsError.new(api_res['response']['resource_id']), api_res['response']['message']
    else
      raise "Unexpected error: \n#{api_res.inspect}"
    end

    res
  end

# POST with subscription_id to issue (or re-issue) an opt-in email.
# POST with subscriber_id and list_id to create a new subscription and send an opt-in email
# in the same request.
# @param [Integer] subscription_id
# @param [Integer] subscriber_id
# @param [Integer] list_id
# @param [String] redirection_url
  def send_optin_email(subscription_id = 0, subscriber_id = 0, list_id = 0, redirection_url: '')

    unless subscription_id > 0 || (subscriber_id > 0 && list_id > 0)
      raise 'You must either provide a subscription_id OR (subscriber_id AND list_id)'
    end

    attributes                    = {}
    attributes['subscription_id'] = subscription_id if subscription_id > 0
    attributes['subscriber_id']   = subscriber_id if subscriber_id > 0
    attributes['list_id']         = list_id if list_id > 0
    attributes['redirectionurl']  = redirection_url unless redirection_url.empty?

    api_res = request 'post', 'emailOptIn', :body => attributes

    if api_res['status'] == STATUS_ERROR && api_res['response']['code'] == 409
      raise SubscriptionExistsError.new(api_res['response']['resource_id']), api_res['response']['message']
    elsif api_res['status'] == STATUS_ERROR
      raise "Unexpected error: \n#{api_res.inspect}"
    end

    api_res
  end

# @param [Integer] id The unique identifier of the subscriber profile data
# @param [Integer] subscriber_id The unique identifier of the subscriber to which this record pertains
# @param [Integer] profile_field_id The identifier of the subscriber profile field for which this datum stores a value
  def get_profile_data(id: 0, subscriber_id: 0, profile_field_id: 0)

    unless id > 0 || subscriber_id > 0 || profile_field_id > 0
      raise 'You must provide at least one of the required identifiers'
    end

    attributes                    = {}
    attributes['id'] = id if id > 0
    attributes['subscriber_id'] = subscriber_id if subscriber_id > 0
    attributes['subscriberprofilefield_id'] = profile_field_id if profile_field_id > 0

    api_res = request 'get', 'subscriberProfileData', :query => attributes

    res = {} # 404
    if api_res && api_res['status'] == STATUS_OK
      res = {}

      api_res['response']['data'].each do |data|
        res[data['subscriberprofilefield_id']] = data['value']
      end
    elsif api_res['status'] == STATUS_ERROR && api_res['response']['code'] != 404
      raise "Unexpected error: \n#{api_res.inspect}"
    end

    res
  end

  def update_profile_data(subscriber_id, data)

    unless subscriber_id > 0 && !data.empty?
      raise 'Please provide the subscriber_id and a valid set of data'
    end

    data.each do |field_id, value|
      attributes                              = {}
      attributes['subscriber_id']             = subscriber_id
      attributes['subscriberprofilefield_id'] = field_id
      attributes['value']                     = value

      request 'post', 'subscriberProfileData', :body => attributes
    end
  end

# ----------
  private # -------------------------------------------------------------------

# noinspection RubyStringKeysInHashInspection
# @param [String] verb
# @param [String] endpoint
  def get_headers(verb, endpoint)
    t         = Time.now
    req_date  = t.httpdate
    req_nonce = UUIDTools::UUID.random_create.to_s

    headers = {
        'Date'        => req_date,
        'X-SuT-CID'   => @cid.to_s,
        'X-SuT-UID'   => @uid.to_s,
        'X-SuT-Nonce' => req_nonce,
    }

    sig_headers = []

    sig_headers << "#{verb.upcase} /v#{VERSION}/#{endpoint}"
    headers.each do |key, val|
      sig_headers << "#{key}: #{val}"
    end
    sig_headers << @hash

    sig_string = sig_headers.join "\r\n"
    signature  = Digest::SHA1.hexdigest sig_string

    headers['Authorization'] = "SuTHash signature=\"#{signature}\""

    headers
  end

# @param [String] verb
# @param [String] endpoint
# @param [Hash] query
# @param [Hash|String] body
  def request(verb, endpoint, query: {}, body: {})
    headers = get_headers(verb, endpoint)

    case verb.downcase
      when 'get'
        response = self.class.get("/#{endpoint}", :headers => headers, :query => query)
      when 'post'
        response = self.class.post(
            "/#{endpoint}",
            :headers => headers,
            :query   => query,
            :body    => body
        )
      when 'put'
        response = self.class.put(
            "/#{endpoint}",
            :headers => headers,
            :query   => query,
            :body    => body
        )
      else
        raise "Invalid verb specified: #{verb}"
    end

    response
  end

end