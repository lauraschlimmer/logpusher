class LogfileUploader
  def buildJSONForLogline(logline)
    raise NotImplementedError
  end

  def upload(records)
    raise NotImplementedError
  end
end
