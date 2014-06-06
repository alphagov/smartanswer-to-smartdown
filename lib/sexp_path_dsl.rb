module SexpPathDsl
  def Q?(&block)
    SexpPath::SexpQueryBuilder.do(&block)
  end
end
