package com.tinyspeck.engine.util
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.itemstack.Itemstack;

	final public class ContainersUtil
	{
		// rarely called, no need for optimization
		public static function getTsidAForContainerTsid(container_tsid:String, tsids:Object, all_itemstacks_hash:Object):Array {
			return getItemstackTsidAsGroupedByContainer(tsids, all_itemstacks_hash)[container_tsid];
		}

		// NOTE: This function may look ridiculous but it's been hand optimized;
		// memcaching won't help because the most common calls are with the same
		// Dictionary objects that may change dynamically between calls
		public static function getItemstackTsidAsGroupedByContainer(tsids:Object, all_itemstacks_hash:Object):Object
		{
			var itemstack:Itemstack;
			// the ones with no container go here
			const rootA:Array = [];
			var containerA:Array;
			const As:Object = {
				root: rootA
			};

			// since tsids can be an Array or Dictionary
			// (for .. in versus for each .. in, when grabbing the tsid values),
			// there's no single loop type which will let us iterate over either
			// values or keys without having to transform one to another first,
			// hence code duplication (and don't use a helper function!), sigh.
			if (tsids is Array) {
				const tsidsA:Array = tsids as Array;
				var i:int = tsidsA.length-1;
				for (; i>=0; --i) {
					itemstack = (all_itemstacks_hash[tsidsA[int(i)]] as Itemstack);
					// <DUPLICATE>
					CONFIG::debugging {
						if (!itemstack)	Console.warn(tsidsA[int(i)] + ' not exists');
					}
					if (itemstack) {
						if (itemstack.container_tsid) {
							containerA = (As[itemstack.container_tsid] as Array);
							if (!containerA) {
								As[itemstack.container_tsid] = [itemstack.tsid];
							} else {
								containerA.push(itemstack.tsid);
							}
						} else {
							rootA.push(itemstack.tsid);
						}
					}
					// </DUPLICATE>
				}
			} else {
				for (var tsid:String in tsids) {
					itemstack = (all_itemstacks_hash[tsid] as Itemstack);
					// <DUPLICATE>
					CONFIG::debugging {
						if (!itemstack)	Console.warn(tsidsA[int(i)] + ' not exists');
					}
					if (itemstack) {
						if (itemstack.container_tsid) {
							containerA = (As[itemstack.container_tsid] as Array);
							if (!containerA) {
								As[itemstack.container_tsid] = [itemstack.tsid];
							} else {
								containerA.push(itemstack.tsid);
							}
						} else {
							rootA.push(itemstack.tsid);
						}
					}
					// </DUPLICATE>
				}
			}
			return As;
		}
	}
}