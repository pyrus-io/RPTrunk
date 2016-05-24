
public struct EventResult {
    public let event:Event
    public let effects:[ConflictResult]
    
    init(_ event:Event, _ effects:[ConflictResult]) {
        self.event = event
        self.effects = effects
    }
}

public struct Event {
    unowned public let initiator: Entity
    public let ability:Ability
    
    public var targets: [Entity] {
        
        //TODO: Iterate over components and potentially modify target selection (i.e 'All' component)
        switch ability.targetType {
        case .Oneself:
            return [initiator]
        case .SingleEnemy:
            return initiator.target != nil ? [initiator.target!] : []
        case .All:
            return initiator.targets
        default:
            return []
        }
    }
    
    public init(initiator: Entity, ability:Ability) {
        self.initiator = initiator
        self.ability = ability
    }
    
    func getStats() -> Stats {
        return ability.stats
    }
    
    func getCost() -> Stats {
        return ability.cost * -1
    }
    
    func applyStatusEffectChanges() {
        
        ability.dischargedStatusEffects
            .forEach {
                name in
                targets.forEach { $0.dischargeStatusEffect(name) }
            }
        
        ability.statusEffects
            .forEach {
                se in
                targets.forEach { $0.applyStatusEffect(se) }
        }
    }
    
    //MARK: - Results calculation and application
    
    public func getResults() -> [ConflictResult] {
        let totalStats = getStats()
        let results = targets.map { (target) -> ConflictResult in
            return RPGameEnvironment.current.delegate.resolveConflict(self, target:target, conflict: totalStats)
        }
        let costResult = RPGameEnvironment.current.delegate.resolveConflict(self, target:initiator, conflict: getCost())
        return results + [costResult]
    }
    
    func applyResults(results:[ConflictResult]){
        results.forEach { (result) -> () in
            result.entity.setCurrentStats(result.entity.allCurrentStats() + result.change)
        }
        applyStatusEffectChanges()
    }
    
    public func execute() -> EventResult {
        let results = getResults()
        applyResults(results)
        return EventResult(self, results)
    }
    
}
