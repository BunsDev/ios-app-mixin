import UIKit

extension UILocalizedIndexedCollation {
    
    func catalog<Object>(_ objects: [Object], usingSelector selector: Selector) -> (titles: [String], sections: [[Object]]) {
        var sections: [[Object]] = Array(repeating: [], count: sectionTitles.count)
        for object in objects {
            let sectionIndex = section(for: object, collationStringSelector: selector)
            sections[sectionIndex].append(object)
        }
        var titles = sectionIndexTitles
        var result = [[Object]]()
        for (index, section) in sections.enumerated().reversed() {
            if section.count > 0 {
                let sorted = sortedArray(from: section, collationStringSelector: selector) as! [Object]
                result.insert(sorted, at: 0)
            } else {
                titles.remove(at: index)
            }
        }
        return (titles: titles, sections: result)
    }
    
}
