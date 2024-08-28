function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 3))
  animator.setParticleEmitterActive("healing", true)

  script.setUpdateDelta(5)

  self.healingRate = config.getParameter("healAmount", 30) / effect.duration()
  self.cancelThreshold = config.getParameter("cancelThreshold", 1)
end

function update(dt)
  status.modifyResource("health", self.healingRate * dt)

  for _, notif in pairs(status.damageTakenSince()) do
    if notif.healthLost / status.resourceMax("health") >= self.cancelThreshold then
      effect.expire()
    end
  end
end

function uninit() end