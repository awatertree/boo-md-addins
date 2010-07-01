namespace Boo.MonoDevelop.Completion

import System
import Boo.Lang.PatternMatching

import MonoDevelop.Projects.Dom
import MonoDevelop.Ide.CodeCompletion

import Boo.MonoDevelop.Util.Completion

class BooEditorCompletion(BooCompletionTextEditorExtension):
	
	# Match "blah as [...]" pattern
	static AS_PATTERN = /\bas\s+(?<namespace>[\w\d]+(\.[\w\d]+)*)?\.?/
	
	# Match "Blah[of ...]" pattern
	static OF_PATTERN = /\bof\s+(?<namespace>[\w\d]+(\.[\w\d]+)*)?\.?/
	
	# Patterns that result in us doing a type completion
	static TYPE_PATTERNS = [OF_PATTERN, AS_PATTERN]
	
	# Patterns that result in us doing a namespace completion
	static NAMESPACE_PATTERNS = [IMPORTS_PATTERN]
	
	# Delimiters that indicate a literal
	static LITERAL_DELIMITERS = ['"', '/']
	
	override def Initialize():
		super()
		
	override def HandleCodeCompletion(context as CodeCompletionContext, completionChar as char):
		triggerWordLength = 0
		return HandleCodeCompletion(context, completionChar, triggerWordLength)
		
	override def HandleCodeCompletion(context as CodeCompletionContext, completionChar as char, ref triggerWordLength as int):
#		print "HandleCodeCompletion(${context.ToString()}, ${completionChar.ToString()})"
		triggerWordLength = 0
		line = GetLineText(context.TriggerLine)
		
		if(IsInsideComment(line, context.TriggerLineOffset-2) or \
		   IsInsideLiteral(line, context.TriggerLineOffset-2)):
			return null
		
		match completionChar.ToString():
			case " ":
				if (null != (completions = CompleteNamespacePatterns(context))):
					return completions
				return CompleteTypePatterns(context)
			case ".":
				if (null != (completions = CompleteNamespacePatterns(context))):
					return completions
				elif (null != (completions = CompleteTypePatterns(context))):
					return completions
				return CompleteMembers(context)
			otherwise:
				if(StartsIdentifier(line, context.TriggerLineOffset-2)):
					# Necessary for completion window to take first identifier character into account
					--context.TriggerOffset 
					triggerWordLength = 1
					
					return CompleteVisible(context)
		return null
				
	def CompleteNamespacePatterns(context as CodeCompletionContext):
		completions as CompletionDataList = null
		types = List[of MemberType]()
		types.Add(MemberType.Namespace)
		
		for pattern in NAMESPACE_PATTERNS:
			return completions if (null != (completions = CompleteNamespacesForPattern(context, pattern,
			                                              "namespace", types)))
		return null
		
	def CompleteTypePatterns(context as CodeCompletionContext):
		completions as CompletionDataList = null
		types = List[of MemberType]()
		types.Add(MemberType.Namespace)
		types.Add(MemberType.Type)
		
		for pattern in TYPE_PATTERNS:
			return completions if (null != (completions = CompleteNamespacesForPattern(context, pattern,
			                                              "namespace", types)))
		return null
			
	override def ShouldEnableCompletionFor(fileName as string):
		return Boo.MonoDevelop.ProjectModel.BooLanguageBinding.IsBooFile(fileName)
		
	def IsInsideComment(line as string, offset as int):
		return line.IndexOf(MonoDevelop.Projects.LanguageBindingService.GetBindingPerFileName(self.Document.FileName).SingleLineCommentTag) <= offset
		
	def IsInsideLiteral(line as string, offset as int):
		fragment = line[0:offset+1]
		for delimiter in LITERAL_DELIMITERS:
			if(0 < fragment.Split(delimiter).Length%2):
				return true
		return false
	
	override SelfReference:
		get: return "self"
