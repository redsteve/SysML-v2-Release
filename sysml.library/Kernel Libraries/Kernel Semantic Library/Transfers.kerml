standard library package Transfers {
	doc
	/*
	 * This package defines the transfer interactions used to type item flows.
	 */

	private import Base::Anything;
	private import Occurrences::*;
	private import Links::*;
	private import Objects::BinaryLinkObject;
	private import Performances::Performance;
	private import Performances::performances;
	private import ScalarValues::Boolean;
	private import ScalarValues::Natural;
	private import SequenceFunctions::*;
	
	interaction Transfer specializes Performance, BinaryLink {
		doc
		/*
		 * A Transfer represents the transfer of items from the source of the interaction 
		 * to the target of the interaction.
		 */
	
		end feature source: Occurrence redefines BinaryLink::source {
			doc
			/*
			 * The entity whose output is the source of the items to be transferred.
			 */
		
			feature sourceOutput: Occurrence[0..*];
		}
		
		end feature target: Occurrence redefines BinaryLink::target {
			doc
			/*
			 * The entity whose input is the target of the items to be transferred.
			 */
		
		    feature targetInput: Occurrence[0..*];
		}
		
		readonly feature isInstant: Boolean[1] {
			doc
			/*
			 * If isInstance is true, then the transfer is instantaneous.
			 */
		}
		
		feature item: Anything[1..*] {
			doc
			/*
			 * The items that are transferred.
			 */
		}
		
		feature itemNum: Natural [1] = size(item);
		
		private instantNum: Natural[1] = if isInstant? 1 else 0;
		private binding instant[instantNum] of [0..1] startShot = [0..1] endShot {
			doc
			/*
			 * If isInstant is true, then the start and end of the transfer happen at the same time.
			 */
		}
	}
	
	interaction MessageTransfer specializes Transfer {
		doc
		/*
		 * A MessageTransfer is a Transfer that does not specify where items are picked
		 * up and dropped off (see FlowTransfer).  They are sent by SendPerformances and
		 * accepted by AcceptPerformances.
		 */
	}
	 
	interaction FlowTransfer specializes Transfer disjoint from MessageTransfer {
		doc
		/*
		 * A FlowTransfer is a Transfer identifying an output feature of the source from which
		 * to pick up items and an input feature of the target to drop them off. They can
		 * start when items are available at the source and move or copy them to the target.
		 */
		 
		readonly feature isMove: Boolean[1] default true {
			doc
			/*
			 * If isMove is true, then all items leave the source at the start
			 * of the transfer.
			 */
		}
		
		readonly feature isPush: Boolean[1] default true {
			doc
			/*
			 * If isPush is true, then the transfer begins when the items are available
			 * at the source.
			 */
		}
		
		connector sourceOutputLink: BinaryLinkObject[itemNum] {
			doc
			/*
			 * The output of the items from the sourceOutput.
			 */
		
			end [1] feature transferSource references source;
			end [itemNum] feature transferPayload references item subsets transferSource.sourceOutput;
		}
		
		connector targetInputLink: BinaryLinkObject[itemNum] {
			doc
			/*
			 * The input of the items to the targetInput.
			 */
		
			end [1] feature transferTarget references target;
			end [itemNum] feature transferPayload references item subsets transferTarget.targetInput;
		}
		
		private connector sending: HappensDuring[itemNum] from [1] startShot to [itemNum] sourceOutputLink {
			doc
			/*
			 * The start of the transfer happens during the output of each of the items from the
			 * source. 
			 */
		}
		
		private connector moving: HappensWhile[0..*] from [0..*] sourceOutputLink.endShot to [0..1] startShot {
			doc
			/*
			 * If isMove is true, then all items leave the source at the start
			 * of the transfer.
			 */
		}
		private inv { isMove implies size(moving) == size(sourceOutputLink) }
		
		private connector pushing: HappensWhile[0..*] from [0..*] sourceOutputLink.startShot to [0..1] startShot {
			doc
			/*
			 * If isPush is true, then the transfer begins when the items are available
			 * at the source.
			 */
		}
		private inv { isPush implies size(pushing) == size(sourceOutputLink) }
		
		private connector delivering: HappensWhile[itemNum] from [itemNum] targetInputLink.startShot to [1] endShot {
			doc
			/*
			 * The input of each of the items to the target starts at the end of the transfer.
			 */
		}
	}
	
	interaction TransferBefore specializes Transfer, HappensBefore intersects Transfer, HappensBefore {
		doc
		/*
		 * TransferBefore is a specialization of Transfer in which the source happens before
		 * the transfer, which happens before the target.
		 */
	
	 	end feature source: Occurrence redefines Transfer::source, HappensBefore::earlierOccurrence;
	  	end feature target: Occurrence redefines Transfer::target, HappensBefore::laterOccurrence;
	  	
	  	feature self: TransferBefore redefines Performance::self;
	  	
	  	private succession source then self;
	  	private succession self then target;
	}
	
	interaction FlowTransferBefore specializes FlowTransfer, TransferBefore intersects FlowTransfer, TransferBefore {
		doc
		/*
		 * FlowTransferBefore is a FlowTransfer that is also a TransferBefore. 
		 */
		 
        end feature source: Occurrence redefines Transfer::source, TransferBefore::source;
        end feature target: Occurrence redefines Transfer::target, TransferBefore::target;		 
	}
	
	abstract flow transfers: Transfer[0..*] nonunique subsets performances, binaryLinks {
		doc
		/*
		 * transfers is a specialization of performances and binaryLinks restricted to type 
		 * Transfer.
		 */
	
		end feature source: Occurrence redefines Transfer::source, binaryLinks::source;
		end feature target: Occurrence redefines Transfer::target, binaryLinks::target;
	}
	
	abstract flow messageTransfers: MessageTransfer[0..*] nonunique subsets transfers {
		doc
		/*
		 * messageTransfers is a specialization of transfers restricted to type MessageTransfers.
		 */
		
		end feature source: Occurrence redefines MessageTransfer::source, transfers::source;
		end feature target: Occurrence redefines MessageTransfer::target, transfers::target;		
	}
	
	abstract flow flowTransfers: FlowTransfer[0..*] nonunique subsets transfers {
		doc
		/*
		 * flowTransfers is a specialization of transfers restricted to type FlowTransfers.
		 * It is the default subsetting for non-succession item flows.
		 */
		 
		end feature source: Occurrence redefines FlowTransfer::source, transfers::source;
		end feature target: Occurrence redefines FlowTransfer::target, transfers::target;
	}
	  
	abstract flow transfersBefore: TransferBefore[0..*] nonunique subsets transfers, happensBeforeLinks
		intersects transfers, happensBeforeLinks {
		doc
		/*
		 * transfersBefore is a specialization of transfers and happensBeforeLinks restricted to
		 * type TransferBefore.
		 */
	
		end feature source: Occurrence redefines TransferBefore::source, transfers::source, happensBeforeLinks::earlierOccurrence;
		end feature target: Occurrence redefines TransferBefore::target, transfers::target, happensBeforeLinks::laterOccurrence;
	}
	
	abstract flow flowTransfersBefore: FlowTransferBefore[0..*] nonunique subsets flowTransfers, transfersBefore
		intersects flowTransfers, transfersBefore {
		doc
		/*
		 * flowTransfersBefore is a specialization of flowTransfers and transfersBefore that is restricted
		 * to type FlowTransferBefore. IT is the default subsetting for succession item flows.
		 */
    
		end feature source: Occurrence redefines FlowTransferBefore::source, flowTransfers::source, transfersBefore::source;
		end feature target: Occurrence redefines FlowTransferBefore::target, flowTransfers::target, transfersBefore::target;
	}

	behavior SendPerformance specializes Performance  {
		doc
		/*
		 * SendPerformances are Performance that require an outgoingTransferFromSelf 
		 * from a designated sender Occurrence carrying a given item, optionally to a designated receiver.
		 */
	
		in feature sentItem [0..*];
		in feature sender: Occurrence[1] default this;
		in feature receiver: Occurrence[0..1];
		feature sentTransfer: MessageTransfer [1] subsets sender.outgoingTransfersFromSelf {
            feature redefines item = sentItem;
		}
		binding [0..1] receiver.incomingTransfersToSelf = [1] sentTransfer;

		succession self then sentTransfer;
	}
	
	behavior AcceptPerformance specializes Performance {
		doc
		/*
		 * AcceptPerformance is a performance that requires an incomingTransferToSelf
		 * of a desigated receiver Occurrence, providing its item as output.
		 */
		inout feature acceptedItem[0..*];
		in feature receiver: Occurrence[1] default this;
		feature acceptedTransfer: MessageTransfer[1] subsets receiver.incomingTransfersToSelf;
		succession acceptedTransfer then self.endShot;
		
		binding acceptedItem = acceptedTransfer.item;
	}

	abstract step sendPerformances: SendPerformance[0..*] nonunique subsets performances {
		doc
		/*
		 * sendPerformances is a specialization of performances for SendPerformances.
		 */
	}
		
	abstract step acceptPerformances: AcceptPerformance[0..*] nonunique subsets performances {
		doc
		/*
		 * acceptPerformances is a specialization of performances for AcceptPerformances.
		 */
	}
}