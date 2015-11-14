class TinyException < Exception

  base = 0
  NOPRIVILEGES = base+=1
  SECURITYHACK = base+=1
  ENROLL_INVALIDFACILITATOR = base+=1
  ENROLL_UNAVAILABLE = base+=1
  ENROLL_DUPLICATE = base+=1
  CONTRACTUPDATEFAILED = base +=1
  NOCONTRACT = base +=1

  MESSAGES = {
    NOPRIVILEGES => "You don't have privileges for that action.",
    SECURITYHACK => "#{AppConfig.app_name} encountered an unexpected error.",
    ENROLL_INVALIDFACILITATOR => "That user can't be assigned as a contract facilitator.",
    ENROLL_UNAVAILABLE => "This contract is not marked as enrollable.",
    ENROLL_DUPLICATE => "The person is already enrolled in the contract.",
    CONTRACTUPDATEFAILED => "#{AppConfig.app_name} wasn't able to update the contract.",
    NOCONTRACT => "#{AppConfig.app_name} encountered an unexpected error."
  }
  
  attr_accessor :error_code
  
  # This is the stub for a system-wide error handler.
  # we will funnel system messages through this API. 
  # Global messages defined in the config file.
  
  def initialize(id)
    @error_code = id
  end

  def TinyException.raise_exception(id, user)
    raise TinyException.new(id), MESSAGES[id]
  end
  
end