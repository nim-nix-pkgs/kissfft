import binding
import complex
import math

when (NimMajor, NimMinor, NimPatch) < (0, 19, 9):
  type nimComplex = complex.Complex
else:
  type nimComplex = complex.Complex[kiss_fft_scalar]

type
  Scalar* = binding.kiss_fft_scalar

  Complex* = binding.kiss_fft_cpx

  KissFFT* = object
    cfg: binding.kiss_fft_cfg
    nfft: int
    nfft_rsqrt: Scalar

proc newKissFFT*(nfft: int, inverse_fft: bool): KissFFT =
  return KissFFT(
    cfg: binding.kiss_fft_alloc(cast[cint](nfft), ord(inverse_fft).cint, nil, nil),
    nfft: nfft,
    nfft_rsqrt: 1 / math.sqrt(toFloat(nfft))
  )

proc transform*(self: var KissFFT, fin: openArray[Complex], fout: var openArray[Complex]) =
  assert(len(fin) >= self.nfft)
  assert(len(fout) >= self.nfft)
  assert(self.cfg != nil)
  binding.kiss_fft(self.cfg, cast[ptr binding.kiss_fft_cpx](fin), cast[ptr binding.kiss_fft_cpx](fout))

proc transform_to_seq*(self: var KissFFT, fin: openArray[Complex]): seq[Complex] =
  assert(len(fin) >= self.nfft)
  assert(self.cfg != nil)
  result = newSeq[Complex](self.nfft)
  binding.kiss_fft(self.cfg, cast[ptr binding.kiss_fft_cpx](fin), cast[ptr binding.kiss_fft_cpx](result[0].addr))

proc transform_norm*(self: var KissFFT, fin: openArray[Complex], fout: var openArray[Complex]) =
  self.transform(fin, fout)
  for i in fout.mitems():
    i.r *= self.nfft_rsqrt
    i.i *= self.nfft_rsqrt

proc transform_norm_to_seq*(self: var KissFFT, fin: openArray[Complex]): seq[Complex] =
  result = self.transform_to_seq(fin)
  for i in result.mitems():
    i.r *= self.nfft_rsqrt
    i.i *= self.nfft_rsqrt

proc toNimComplex*(x: Complex): nimComplex =
  result.re = x.r
  result.im = x.i

proc fromNimComplex*(x: nimComplex): Complex =
  result.r = x.re
  result.i = x.im
