/*
 * generated by Xtext 2.12.0
 */
package de.fhdo.lemma.technology.scoping

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import de.fhdo.lemma.technology.Protocol
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.impl.MapBasedScope
import org.eclipse.xtext.resource.EObjectDescription
import de.fhdo.lemma.technology.PossiblyImportedTechnologySpecificType
import org.eclipse.xtext.EcoreUtil2
import de.fhdo.lemma.technology.Technology
import de.fhdo.lemma.data.Type
import java.util.List
import de.fhdo.lemma.typechecking.TypecheckingUtils
import de.fhdo.lemma.technology.CompatibilityMatrixEntry
import de.fhdo.lemma.technology.TechnologyPackage
import de.fhdo.lemma.technology.ServiceAspectPointcut
import org.eclipse.xtext.scoping.Scopes
import org.eclipse.xtext.naming.QualifiedName
import de.fhdo.lemma.technology.OperationAspectPointcut
import de.fhdo.lemma.technology.OperationAspect
import de.fhdo.lemma.technology.JoinPointType
import de.fhdo.lemma.utils.LemmaUtils

/**
 * This class implements a custom scope provider for the Technology DSL.
 *
 * @author <a href="mailto:florian.rademacher@fh-dortmund.de">Florian Rademacher</a>
 */
class TechnologyDslScopeProvider extends AbstractTechnologyDslScopeProvider {
    /**
     * Build scope for a given context and reference
     */
    override getScope(EObject context, EReference reference) {
        val scope = switch (context) {
            /* Protocols */
            Protocol: context.getScope(reference)

            /* Possibly imported microservices */
            PossiblyImportedTechnologySpecificType: context.getScope(reference)

            /* Possibly imported interfaces */
            CompatibilityMatrixEntry: context.getScope(reference)

            /* Service aspect pointcuts */
            ServiceAspectPointcut: context.getScope(reference)

            /* Operation aspect pointcuts */
            OperationAspectPointcut: context.getScope(reference)
        }

        if (scope !== null)
            return scope

        // Try default scope resolution, if no scope could be determined
        else if (scope === null)
            return super.getScope(context, reference)
    }

    /**
     * Build scope for possibly imported technology-specific types
     */
    private def getScope(PossiblyImportedTechnologySpecificType type, EReference reference) {
        if (reference !=
            TechnologyPackage::Literals.POSSIBLY_IMPORTED_TECHNOLOGY_SPECIFIC_TYPE__TYPE)
            return null

        val importUri = if (type.import !== null) type.import.importURI
        return getScopeForPossiblyImportedType(type, importUri)
    }

    /**
     * Build scope for possibly imported technology-specific types with the containing compatibility
     * matrix as context. Note that the matrix is passed as context, if there is not import given.
     */
    private def getScope(CompatibilityMatrixEntry entry, EReference reference) {
        // Called when no import was given, hence the URI must be null
        return getScopeForPossiblyImportedType(entry, null)
    }

    /**
     * Build scope for service aspect pointcuts
     */
    private def getScope(ServiceAspectPointcut pointcut, EReference reference) {
        switch (reference) {
            /* Protocols */
            case TechnologyPackage.Literals::SERVICE_ASPECT_POINTCUT__PROTOCOL:
                return pointcut.getScopeForPointcutProtocols()

            /* Data formats */
            case TechnologyPackage.Literals::SERVICE_ASPECT_POINTCUT__DATA_FORMAT:
                return pointcut.getScopeForPointcutDataFormats()
        }

        return null
    }

    /**
     * Build scope for protocols of aspects pointcuts
     */
    private def getScopeForPointcutProtocols(ServiceAspectPointcut pointcut) {
        if (pointcut === null)
            return null

        val communicationTypePointcuts = pointcut.selector.pointcuts
            .filter[forCommunicationType].map[communicationType].toList
        val technologyModel = EcoreUtil2.getRootContainer(pointcut) as Technology
        var scopeElements = if (!communicationTypePointcuts.empty)
            technologyModel.protocols.filter[communicationTypePointcuts.contains(communicationType)]
        else
            // In case no communication types were selected, return all protocols defined in the
            // technology as elements of the scope
            technologyModel.protocols

        return Scopes::scopeFor(scopeElements)
    }

    /**
     * Build scope for data formats of aspects pointcuts
     */
    private def getScopeForPointcutDataFormats(ServiceAspectPointcut pointcut) {
        if (pointcut === null)
            return null

        val protocolPointcuts = pointcut.selector.pointcuts.filter[forProtocol].toList

        var scopeElements = if (!protocolPointcuts.empty)
            protocolPointcuts.map[protocol].map[dataFormats].flatten.toList
        else {
            // In case no protocols were selected, return all data formats defined in the technology
            // as elements of the scope
            val technologyModel = EcoreUtil2.getRootContainer(pointcut) as Technology
            technologyModel.protocols.map[dataFormats].flatten.toList
        }

        return Scopes::scopeFor(scopeElements, [QualifiedName.create(formatName)],
            IScope.NULLSCOPE)
    }

    /**
     * Build scope for operation aspect pointcuts
     */
    private def getScope(OperationAspectPointcut pointcut, EReference reference) {
        switch (reference) {
            /* Technologies */
            case TechnologyPackage.Literals::OPERATION_ASPECT_POINTCUT__TECHNOLOGY:
                return pointcut.getScopeForOperationAspectPointcutTechnologies()
        }

        return null
    }

    /**
     * Build scope for technologies of operation aspects pointcuts
     */
    private def getScopeForOperationAspectPointcutTechnologies(OperationAspectPointcut pointcut) {
        if (pointcut === null)
            return null

        val joinPoints = EcoreUtil2.getContainerOfType(pointcut, OperationAspect).joinPoints
        val modelRoot = EcoreUtil2.getContainerOfType(pointcut, Technology)
        val scopeElements = <EObject>newArrayList

        if (joinPoints.contains(JoinPointType.CONTAINERS))
            scopeElements.addAll(modelRoot.deploymentTechnologies)

        if (joinPoints.contains(JoinPointType.INFRASTRUCTURE_NODES))
            scopeElements.addAll(modelRoot.infrastructureTechnologies)

        return Scopes::scopeFor(scopeElements)
    }

    /**
     * Build scope for possibly imported technology-specific types w.r.t. the import's URI
     */
    private def getScopeForPossiblyImportedType(EObject context, String importUri) {
        val containingTechnology = EcoreUtil2.getContainerOfType(context, Technology)
        if (containingTechnology === null) {
            return IScope.NULLSCOPE
        }

        val scopedElements = LemmaUtils.getScopeForPossiblyImportedConcept(
            containingTechnology,
            null,
            Technology,
            importUri,
            [val List<Type> types = <Type> newArrayList
             types.addAll(primitiveTypes)
             types.addAll(listTypes)
             types.addAll(dataStructures)
             return types
            ],
            // The name parts are always passed without the qualifying parts. That is, because
            // otherwise the qualifying parts like "types" would collide with eponymous keywords.
            [TypecheckingUtils.getTypeNameParts(it, true)]
        )

        return scopedElements
    }

    /**
     * Build scope for protocol default formats
     */
    private def getScope(Protocol protocol, EReference reference) {
        if (protocol === null)
            return IScope.NULLSCOPE

        // Only a data format defined for the protocol can also be its default protocol
        val scopeElements = protocol.dataFormats.map[
            EObjectDescription.create(it.formatName, it)
        ]

        // Note, that we use a map-based scope here, because the DataFormat metamodel element has
        // no "name" attribute, but a "formatName" attribute, to exclude it from being automatically
        // checked by the unique names validator. That is, because the name of a protocol must only
        // be unique within its protocol, but not the overall model (i.e., over all protocols).
        return MapBasedScope.createScope(IScope.NULLSCOPE, scopeElements)
    }
}